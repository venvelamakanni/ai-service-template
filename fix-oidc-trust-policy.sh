#!/bin/bash

# Script to help fix OIDC trust policy for GitHub Actions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 OIDC Trust Policy Fixer${NC}"
echo ""

# Get AWS Account ID
echo "Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Error: AWS CLI not configured or credentials invalid${NC}"
    echo "   Please run: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo ""

# Get GitHub username and repo
echo "Enter your GitHub information:"
read -p "GitHub username/organization: " GITHUB_USERNAME
read -p "GitHub repository name: " GITHUB_REPO
read -p "IAM role name (default: github-actions-role): " IAM_ROLE_NAME
IAM_ROLE_NAME=${IAM_ROLE_NAME:-github-actions-role}

echo ""
echo -e "${BLUE}📋 Configuration:${NC}"
echo "   AWS Account ID: $AWS_ACCOUNT_ID"
echo "   GitHub: $GITHUB_USERNAME/$GITHUB_REPO"
echo "   IAM Role: $IAM_ROLE_NAME"
echo ""

# Check if OIDC provider exists
echo "Checking OIDC provider..."
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null)

if [ -z "$OIDC_PROVIDER" ]; then
    echo -e "${YELLOW}⚠️  OIDC provider not found${NC}"
    echo "   You need to create it manually in AWS Console:"
    echo "   1. Go to IAM → Identity providers"
    echo "   2. Add provider → OpenID Connect"
    echo "   3. Provider URL: https://token.actions.githubusercontent.com"
    echo "   4. Audience: sts.amazonaws.com"
    echo ""
    OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    echo "   Expected ARN: $OIDC_PROVIDER_ARN"
else
    echo -e "${GREEN}✅ OIDC provider exists: $OIDC_PROVIDER${NC}"
    OIDC_PROVIDER_ARN="$OIDC_PROVIDER"
fi
echo ""

# Check if IAM role exists
echo "Checking IAM role..."
if aws iam get-role --role-name "$IAM_ROLE_NAME" &>/dev/null; then
    echo -e "${GREEN}✅ IAM role exists: $IAM_ROLE_NAME${NC}"
else
    echo -e "${RED}❌ IAM role not found: $IAM_ROLE_NAME${NC}"
    echo "   Please create the role first in AWS Console"
    exit 1
fi
echo ""

# Generate trust policy
echo "Generating trust policy..."
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
)

echo -e "${BLUE}📄 Trust Policy:${NC}"
echo "$TRUST_POLICY" | jq '.' 2>/dev/null || echo "$TRUST_POLICY"
echo ""

# Save to temporary file
TRUST_POLICY_FILE="/tmp/trust-policy-$(date +%s).json"
echo "$TRUST_POLICY" > "$TRUST_POLICY_FILE"
echo -e "${GREEN}✅ Trust policy saved to temporary file: $TRUST_POLICY_FILE${NC}"
echo -e "${YELLOW}   (This is a temporary file and will be cleaned up)${NC}"
echo ""

# Ask if user wants to update the role
read -p "Do you want to update the IAM role trust policy now? (y/n): " UPDATE_ROLE

if [ "$UPDATE_ROLE" = "y" ] || [ "$UPDATE_ROLE" = "Y" ]; then
    echo "Updating IAM role trust policy..."
    if aws iam update-assume-role-policy --role-name "$IAM_ROLE_NAME" --policy-document file://"$TRUST_POLICY_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ Trust policy updated successfully!${NC}"
    else
        echo -e "${RED}❌ Error updating trust policy${NC}"
        echo "   You can update it manually:"
        echo "   1. Go to IAM → Roles → $IAM_ROLE_NAME"
        echo "   2. Click 'Trust relationships' tab"
        echo "   3. Click 'Edit trust policy'"
        echo "   4. Paste the JSON from $TRUST_POLICY_FILE"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Skipping role update${NC}"
    echo "   To update manually:"
    echo "   1. Go to IAM → Roles → $IAM_ROLE_NAME"
    echo "   2. Click 'Trust relationships' tab"
    echo "   3. Click 'Edit trust policy'"
    echo "   4. Paste the JSON from $TRUST_POLICY_FILE"
fi
echo ""

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

echo -e "${BLUE}📋 GitHub Secrets to Configure:${NC}"
echo ""
echo "Go to your GitHub repository → Settings → Secrets and variables → Actions"
echo ""
echo "Add these secrets:"
echo ""
echo "1. AWS_REGION:"
echo "   Value: $(aws configure get region 2>/dev/null || echo 'us-east-1')"
echo ""
echo "2. AWS_IAM_ROLE_ARN:"
echo "   Value: $ROLE_ARN"
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify GitHub secrets are set"
echo "2. Re-run the GitHub Actions workflow"
echo "3. Check the 'Configure AWS credentials' step"
echo ""

# Clean up temporary file if user didn't want to update
if [ "$UPDATE_ROLE" != "y" ] && [ "$UPDATE_ROLE" != "Y" ]; then
    echo "Trust policy JSON is saved in: $TRUST_POLICY_FILE"
    echo "You can copy it to update the role manually, then delete the file."
fi


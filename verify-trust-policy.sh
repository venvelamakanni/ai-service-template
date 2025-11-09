#!/bin/bash

# Script to verify OIDC trust policy configuration

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying OIDC Trust Policy Configuration${NC}"
echo ""

# Expected values from user's trust policy
EXPECTED_GITHUB_USER="venvelakanni"
EXPECTED_REPO="ai-service-template"
EXPECTED_ACCOUNT_ID="016401511161"
IAM_ROLE_NAME="github-actions-role"

echo -e "${BLUE}📋 Expected Configuration:${NC}"
echo "   GitHub User: $EXPECTED_GITHUB_USER"
echo "   Repository: $EXPECTED_REPO"
echo "   AWS Account ID: $EXPECTED_ACCOUNT_ID"
echo "   IAM Role: $IAM_ROLE_NAME"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Error: AWS CLI not configured${NC}"
    exit 1
fi

echo -e "${BLUE}1. Verifying AWS Account ID${NC}"
if [ "$AWS_ACCOUNT_ID" = "$EXPECTED_ACCOUNT_ID" ]; then
    echo -e "   ${GREEN}✅ Account ID matches: $AWS_ACCOUNT_ID${NC}"
else
    echo -e "   ${YELLOW}⚠️  Account ID mismatch: Expected $EXPECTED_ACCOUNT_ID, got $AWS_ACCOUNT_ID${NC}"
fi
echo ""

# Check OIDC provider
echo -e "${BLUE}2. Checking OIDC Provider${NC}"
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null)

if [ -z "$OIDC_PROVIDER" ]; then
    echo -e "   ${RED}❌ OIDC provider not found${NC}"
    echo "   Expected: arn:aws:iam::${EXPECTED_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
else
    echo -e "   ${GREEN}✅ OIDC provider exists: $OIDC_PROVIDER${NC}"
    
    # Verify account ID in OIDC provider ARN
    if echo "$OIDC_PROVIDER" | grep -q "$EXPECTED_ACCOUNT_ID"; then
        echo -e "   ${GREEN}   ✅ Account ID in OIDC provider ARN matches${NC}"
    else
        echo -e "   ${YELLOW}   ⚠️  Account ID in OIDC provider ARN doesn't match${NC}"
    fi
fi
echo ""

# Check IAM role
echo -e "${BLUE}3. Checking IAM Role${NC}"
if aws iam get-role --role-name "$IAM_ROLE_NAME" &>/dev/null; then
    echo -e "   ${GREEN}✅ IAM role exists: $IAM_ROLE_NAME${NC}"
    
    # Get trust policy
    TRUST_POLICY=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)
    
    if [ -n "$TRUST_POLICY" ]; then
        echo -e "   ${GREEN}✅ Trust policy found${NC}"
        
        # Check if it contains the correct repo
        if echo "$TRUST_POLICY" | grep -q "repo:${EXPECTED_GITHUB_USER}/${EXPECTED_REPO}"; then
            echo -e "   ${GREEN}   ✅ Repository in trust policy matches: repo:${EXPECTED_GITHUB_USER}/${EXPECTED_REPO}:*${NC}"
        else
            echo -e "   ${YELLOW}   ⚠️  Repository in trust policy might not match${NC}"
            echo "   Current trust policy:"
            echo "$TRUST_POLICY" | jq '.' 2>/dev/null || echo "$TRUST_POLICY"
        fi
        
        # Check if it has the correct OIDC provider
        if echo "$TRUST_POLICY" | grep -q "token.actions.githubusercontent.com"; then
            echo -e "   ${GREEN}   ✅ OIDC provider in trust policy is correct${NC}"
        else
            echo -e "   ${RED}   ❌ OIDC provider not found in trust policy${NC}"
        fi
        
        # Check if it has AssumeRoleWithWebIdentity
        if echo "$TRUST_POLICY" | grep -q "AssumeRoleWithWebIdentity"; then
            echo -e "   ${GREEN}   ✅ Action is correct: sts:AssumeRoleWithWebIdentity${NC}"
        else
            echo -e "   ${RED}   ❌ Action is incorrect${NC}"
        fi
    else
        echo -e "   ${RED}❌ Could not retrieve trust policy${NC}"
    fi
else
    echo -e "   ${RED}❌ IAM role not found: $IAM_ROLE_NAME${NC}"
fi
echo ""

# Check role permissions
echo -e "${BLUE}4. Checking IAM Role Permissions${NC}"
POLICIES=$(aws iam list-attached-role-policies --role-name "$IAM_ROLE_NAME" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)

REQUIRED_POLICIES=("AWSAppRunnerFullAccess" "AmazonEC2ContainerRegistryFullAccess" "AmazonS3FullAccess" "AmazonDynamoDBFullAccess" "IAMFullAccess")

for policy in "${REQUIRED_POLICIES[@]}"; do
    if echo "$POLICIES" | grep -q "$policy"; then
        echo -e "   ${GREEN}✅ $policy attached${NC}"
    else
        echo -e "   ${YELLOW}⚠️  $policy not attached (recommended)${NC}"
    fi
done
echo ""

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null)

echo -e "${BLUE}📋 Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your trust policy looks correct! ✅"
echo ""
echo "Expected GitHub repository:"
echo "   https://github.com/$EXPECTED_GITHUB_USER/$EXPECTED_REPO"
echo ""
echo "GitHub Secrets should be:"
echo "   AWS_REGION: $(aws configure get region 2>/dev/null || echo 'us-east-1')"
echo "   AWS_IAM_ROLE_ARN: $ROLE_ARN"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Common issues checklist
echo -e "${BLUE}🔍 Common Issues to Check:${NC}"
echo ""
echo "1. ✅ Trust policy structure looks correct"
echo "2. ⚠️  Verify GitHub repository name matches exactly (case-sensitive)"
echo "   Expected: repo:venvelakanni/ai-service-template:*"
echo "   Your repo: https://github.com/venvelakanni/ai-service-template"
echo ""
echo "3. ⚠️  Wait 1-2 minutes after updating trust policy for changes to propagate"
echo ""
echo "4. ⚠️  Verify GitHub Secrets are set correctly:"
echo "   - AWS_REGION"
echo "   - AWS_IAM_ROLE_ARN"
echo ""
echo "5. ⚠️  Check GitHub Actions workflow uses the correct repository"
echo ""
echo -e "${GREEN}✅ If all checks pass, try re-running the GitHub Actions workflow${NC}"
echo ""


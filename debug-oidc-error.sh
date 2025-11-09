#!/bin/bash

# Comprehensive OIDC Error Debugging Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Comprehensive OIDC Error Debugging${NC}"
echo ""

# Get current trust policy
echo -e "${BLUE}1. Current Trust Policy in AWS:${NC}"
TRUST_POLICY=$(aws iam get-role --role-name github-actions-role --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)
echo "$TRUST_POLICY" | jq '.'
echo ""

# Check OIDC provider
echo -e "${BLUE}2. OIDC Provider Details:${NC}"
OIDC_ARN="arn:aws:iam::016401511161:oidc-provider/token.actions.githubusercontent.com"
OIDC_DETAILS=$(aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" 2>/dev/null)

if [ -n "$OIDC_DETAILS" ]; then
    echo "$OIDC_DETAILS" | jq '{Url:Url,ClientIDList:ClientIDList,ThumbprintList:ThumbprintList}'
    echo -e "${GREEN}✅ OIDC provider exists${NC}"
else
    echo -e "${RED}❌ OIDC provider not found or error accessing it${NC}"
fi
echo ""

# Common issues and solutions
echo -e "${BLUE}3. Common Issues and Solutions:${NC}"
echo ""

echo -e "${YELLOW}Issue 1: Repository Name Mismatch${NC}"
echo "   Your trust policy expects: repo:venvelakanni/ai-service-template:*"
echo "   Verify your GitHub repo URL matches exactly (case-sensitive)"
echo "   Expected: https://github.com/venvelakanni/ai-service-template"
echo ""

echo -e "${YELLOW}Issue 2: OIDC Provider Thumbprint${NC}"
echo "   If the thumbprint is wrong, the OIDC provider won't work"
echo "   Solution: Delete and recreate the OIDC provider"
echo ""

echo -e "${YELLOW}Issue 3: Trust Policy Condition Too Restrictive${NC}"
echo "   Try temporarily using a less restrictive condition to test:"
echo "   Change: \"repo:venvelakanni/ai-service-template:*\""
echo "   To:     \"repo:*/*:*\" (allows all repos - for testing only!)"
echo ""

echo -e "${YELLOW}Issue 4: GitHub Repository Name in Workflow${NC}"
echo "   Make sure the workflow is running from the correct repository"
echo "   Check: GitHub repository → Settings → Check repository name"
echo ""

echo -e "${BLUE}4. Recommended Fix: Try Less Restrictive Trust Policy (Temporary)${NC}"
echo ""
read -p "Do you want to see a less restrictive trust policy for testing? (y/n): " SHOW_POLICY

if [ "$SHOW_POLICY" = "y" ] || [ "$SHOW_POLICY" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This is less secure - use only for testing!${NC}"
    echo ""
    echo "Temporary Trust Policy (allows all GitHub repos):"
    cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::016401511161:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:*/*:*"
        }
      }
    }
  ]
}
EOF
    echo ""
    echo "To test:"
    echo "1. Update the trust policy with this (temporarily)"
    echo "2. Re-run the GitHub Actions workflow"
    echo "3. If it works, the issue is with the repository name condition"
    echo "4. Then restrict it back to your specific repo"
fi
echo ""

echo -e "${BLUE}5. Check GitHub Secrets:${NC}"
echo ""
echo "Verify these secrets are set in GitHub:"
echo "   - AWS_REGION: us-east-1"
echo "   - AWS_IAM_ROLE_ARN: arn:aws:iam::016401511161:role/github-actions-role"
echo ""

echo -e "${BLUE}6. Check CloudTrail Logs:${NC}"
echo ""
echo "To see detailed error messages:"
echo "1. Go to AWS CloudTrail Console"
echo "2. Click 'Event history'"
echo "3. Filter by: Event name = 'AssumeRoleWithWebIdentity'"
echo "4. Look for error messages with more details"
echo ""

echo -e "${BLUE}7. Verify GitHub Repository:${NC}"
echo ""
echo "Make sure:"
echo "   - Repository name: ai-service-template"
echo "   - Owner: venvelakanni"
echo "   - Repository URL: https://github.com/venvelakanni/ai-service-template"
echo "   - The workflow is running from this exact repository"
echo ""

echo -e "${GREEN}✅ Debugging complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify GitHub repository name matches exactly"
echo "2. Check GitHub secrets are set correctly"
echo "3. Try the less restrictive trust policy (temporarily) to test"
echo "4. Check CloudTrail logs for detailed error messages"
echo ""


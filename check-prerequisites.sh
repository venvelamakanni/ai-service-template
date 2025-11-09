#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking AWS Prerequisites for GitHub Actions CI/CD..."
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "   Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "   Please run: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is installed and configured${NC}"
echo ""

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo ""

# Check S3 bucket (update bucket name if different)
S3_BUCKET="my-architect-terraform-state-2025"
echo "1. Checking S3 bucket: $S3_BUCKET"
if aws s3 ls "s3://$S3_BUCKET" &>/dev/null; then
    echo -e "   ${GREEN}✅ S3 bucket exists${NC}"
    
    # Check versioning
    VERSIONING=$(aws s3api get-bucket-versioning --bucket "$S3_BUCKET" --query Status --output text 2>/dev/null)
    if [ "$VERSIONING" == "Enabled" ]; then
        echo -e "   ${GREEN}✅ Versioning is enabled${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Versioning is not enabled (recommended)${NC}"
    fi
else
    echo -e "   ${RED}❌ S3 bucket not found${NC}"
    echo "   Please create the bucket: $S3_BUCKET"
fi
echo ""

# Check DynamoDB table
DYNAMODB_TABLE="terraform-lock-table"
echo "2. Checking DynamoDB table: $DYNAMODB_TABLE"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" &>/dev/null; then
    echo -e "   ${GREEN}✅ DynamoDB table exists${NC}"
    
    # Check partition key
    PARTITION_KEY=$(aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --query 'Table.KeySchema[0].AttributeName' --output text 2>/dev/null)
    if [ "$PARTITION_KEY" == "LockID" ]; then
        echo -e "   ${GREEN}✅ Partition key is 'LockID' (correct)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Partition key is '$PARTITION_KEY' (should be 'LockID')${NC}"
    fi
else
    echo -e "   ${RED}❌ DynamoDB table not found${NC}"
    echo "   Please create the table: $DYNAMODB_TABLE"
fi
echo ""

# Check OIDC provider
echo "3. Checking GitHub OIDC provider"
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' --output text 2>/dev/null)
if [ -n "$OIDC_PROVIDER" ]; then
    echo -e "   ${GREEN}✅ OIDC provider exists${NC}"
    echo "   Provider ARN: $OIDC_PROVIDER"
else
    echo -e "   ${RED}❌ OIDC provider not found${NC}"
    echo "   Please create OIDC provider for GitHub Actions"
fi
echo ""

# Check IAM role
IAM_ROLE="github-actions-role"
echo "4. Checking IAM role: $IAM_ROLE"
if aws iam get-role --role-name "$IAM_ROLE" &>/dev/null; then
    echo -e "   ${GREEN}✅ IAM role exists${NC}"
    
    # Get role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE" --query 'Role.Arn' --output text 2>/dev/null)
    echo "   Role ARN: $ROLE_ARN"
    
    # Check attached policies
    POLICIES=$(aws iam list-attached-role-policies --role-name "$IAM_ROLE" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)
    echo "   Attached policies: $POLICIES"
    
    # Check for required policies
    REQUIRED_POLICIES=("AWSAppRunnerFullAccess" "AmazonEC2ContainerRegistryFullAccess" "AmazonS3FullAccess" "AmazonDynamoDBFullAccess")
    for policy in "${REQUIRED_POLICIES[@]}"; do
        if echo "$POLICIES" | grep -q "$policy"; then
            echo -e "   ${GREEN}   ✅ $policy attached${NC}"
        else
            echo -e "   ${YELLOW}   ⚠️  $policy not attached (recommended)${NC}"
        fi
    done
else
    echo -e "   ${RED}❌ IAM role not found${NC}"
    echo "   Please create the IAM role: $IAM_ROLE"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary:"
echo ""
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
if [ -n "$ROLE_ARN" ]; then
    echo "IAM Role ARN: $ROLE_ARN"
    echo ""
    echo "📝 GitHub Secrets to configure:"
    echo "   AWS_REGION: $AWS_REGION"
    echo "   AWS_IAM_ROLE_ARN: $ROLE_ARN"
    echo "   AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Update terraform/backend.tf with your S3 bucket name (if different)"
echo "2. Configure GitHub Secrets with the values above"
echo "3. Push to main branch to trigger the workflow"
echo ""


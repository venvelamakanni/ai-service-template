# Prerequisites Checklist for GitHub Actions CI/CD

## ✅ Step 1: AWS S3 Bucket for Terraform State

**Status:** ☐ Not Created ☐ Created

**Instructions:**
1. Go to AWS S3 Console: https://s3.console.aws.amazon.com/
2. Click "Create bucket"
3. Bucket name: `my-architect-terraform-state-2025` (or your unique name)
4. Region: `us-east-1` (or your preferred region)
5. **Uncheck** "Block all public access" (we'll set it private via bucket policy)
6. Enable "Bucket Versioning"
7. Click "Create bucket"

**Verify:**
```bash
aws s3 ls | grep terraform-state
```

---

## ✅ Step 2: DynamoDB Table for Terraform Locking

**Status:** ☐ Not Created ☐ Created

**Instructions:**
1. Go to AWS DynamoDB Console: https://console.aws.amazon.com/dynamodb/
2. Click "Create table"
3. Table name: `terraform-lock-table`
4. Partition key: `LockID` (type: String)
5. Leave all other settings as default
6. Click "Create table"

**Verify:**
```bash
aws dynamodb list-tables | grep terraform-lock-table
```

---

## ✅ Step 3: Update Terraform Backend Configuration

**Status:** ☐ Not Updated ☐ Updated

**File:** `terraform/backend.tf`

**Verify the bucket name matches what you created:**
```hcl
terraform {
  backend "s3" {
    bucket = "my-architect-terraform-state-2025"  # ← Update this if different
    key = "ai-service-template/terraform.tfstate"
    region = "us-east-1"  # ← Update this if different
    dynamodb_table = "terraform-lock-table"
    encrypt = true
  }
}
```

---

## ✅ Step 4: GitHub OIDC Provider in AWS

**Status:** ☐ Not Created ☐ Created

**Instructions:**
1. Go to AWS IAM Console → Identity providers: https://console.aws.amazon.com/iam/home#/providers
2. Click "Add provider"
3. Provider type: **OpenID Connect**
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Click "Get thumbprint" (AWS will automatically fetch it)
7. Click "Add provider"

**Verify:**
```bash
aws iam list-open-id-connect-providers
```

---

## ✅ Step 5: IAM Role for GitHub Actions

**Status:** ☐ Not Created ☐ Created

**Instructions:**
1. Go to AWS IAM Console → Roles: https://console.aws.amazon.com/iam/home#/roles
2. Click "Create role"
3. Trusted entity type: **Web identity**
4. Identity provider: Select `token.actions.githubusercontent.com`
5. Audience: Select `sts.amazonaws.com`
6. **Condition (Optional but recommended):**
   - Condition key: `StringEquals`
   - Key: `token.actions.githubusercontent.com:sub`
   - Value: `repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*`
     - Example: `repo:bharadwajvvs/ai-service-template:*`
7. Click "Next"
8. Attach these policies:
   - `AWSAppRunnerFullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonDynamoDBFullAccess`
   - `IAMFullAccess` (for creating App Runner IAM role)
9. Click "Next"
10. Role name: `github-actions-role` (or your preferred name)
11. Click "Create role"
12. **Copy the Role ARN** (you'll need it for GitHub Secrets)

**Verify:**
```bash
aws iam get-role --role-name github-actions-role
```

---

## ✅ Step 6: GitHub Repository Secrets

**Status:** ☐ Not Set ☐ Set

**Instructions:**
1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click "New repository secret" and add:

### Secret 1: AWS_REGION
- Name: `AWS_REGION`
- Value: `us-east-1` (or your AWS region)

### Secret 2: AWS_IAM_ROLE_ARN
- Name: `AWS_IAM_ROLE_ARN`
- Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role`
  - Replace `YOUR_ACCOUNT_ID` with your 12-digit AWS account ID
  - Replace `github-actions-role` if you used a different role name

### Secret 3: AWS_ACCOUNT_ID (Optional - for reference)
- Name: `AWS_ACCOUNT_ID`
- Value: Your 12-digit AWS account ID (e.g., `123456789012`)

**Verify:**
- Go to: **Settings** → **Secrets and variables** → **Actions**
- You should see all three secrets listed

**Get your AWS Account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```

---

## ✅ Step 7: Verify GitHub Repository Name

**Status:** ☐ Not Verified ☐ Verified

**Important:** Make sure the repository name in GitHub matches what you configured in the IAM role condition (Step 5).

**Check your repository:**
- GitHub username: `_________________`
- Repository name: `_________________`
- Full path: `repo:_________________/_________________:*`

---

## ✅ Step 8: Test Locally (Optional but Recommended)

**Status:** ☐ Not Tested ☐ Tested

**Test Terraform configuration:**
```bash
cd terraform
terraform init
terraform validate
terraform plan -var="aws_region=us-east-1" -var="app_name=ai-service" -var="image_tag=test"
```

**Expected:** No errors, Terraform should show plan to create:
- IAM Role
- IAM Role Policy
- ECR Repository
- App Runner Service

---

## 🚀 Step 9: Trigger GitHub Actions

**Once all above steps are complete:**

1. **Make a commit and push to main branch:**
   ```bash
   git add .
   git commit -m "Trigger CI/CD pipeline"
   git push origin main
   ```

2. **Monitor the workflow:**
   - Go to GitHub repository → **Actions** tab
   - Click on the running workflow
   - Watch Job 1 → Job 2 → Job 3 execute

3. **Check for errors:**
   - If Job 1 fails: Check AWS credentials, IAM role, S3 bucket, DynamoDB table
   - If Job 2 fails: Check ECR repository was created, Docker build issues
   - If Job 3 fails: Check image was pushed, App Runner configuration

4. **Get the service URL:**
   - After Job 3 completes, check the logs for "Service URL"
   - Or run: `terraform output service_url` (if you have AWS CLI configured)

---

## 🔍 Troubleshooting

### Error: "Error acquiring the state lock"
**Solution:** Someone else is running Terraform, or a previous run failed. Check DynamoDB table for locks.

### Error: "Access Denied" when accessing S3
**Solution:** Check IAM role has `AmazonS3FullAccess` policy attached.

### Error: "Repository not found" in ECR
**Solution:** Make sure Job 1 completed successfully and created the ECR repository.

### Error: "Image not found" in App Runner
**Solution:** Make sure Job 2 completed successfully and pushed the Docker image.

### Error: "Invalid role ARN" in App Runner
**Solution:** Make sure the IAM role for App Runner was created in Job 1.

---

## 📋 Quick Verification Script

Run this to verify your AWS setup:

```bash
#!/bin/bash

echo "🔍 Checking AWS Prerequisites..."

# Check S3 bucket
echo "1. Checking S3 bucket..."
aws s3 ls s3://my-architect-terraform-state-2025 2>/dev/null && echo "   ✅ S3 bucket exists" || echo "   ❌ S3 bucket not found"

# Check DynamoDB table
echo "2. Checking DynamoDB table..."
aws dynamodb describe-table --table-name terraform-lock-table 2>/dev/null && echo "   ✅ DynamoDB table exists" || echo "   ❌ DynamoDB table not found"

# Check OIDC provider
echo "3. Checking OIDC provider..."
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com && echo "   ✅ OIDC provider exists" || echo "   ❌ OIDC provider not found"

# Check IAM role
echo "4. Checking IAM role..."
aws iam get-role --role-name github-actions-role 2>/dev/null && echo "   ✅ IAM role exists" || echo "   ❌ IAM role not found"

echo "✅ Verification complete!"
```

Save this as `check-prerequisites.sh`, make it executable (`chmod +x check-prerequisites.sh`), and run it.

---

## ✅ Final Checklist

Before pushing to trigger GitHub Actions:

- [ ] S3 bucket created and versioning enabled
- [ ] DynamoDB table created with LockID partition key
- [ ] Terraform backend.tf updated with correct bucket name
- [ ] GitHub OIDC provider created in AWS
- [ ] IAM role created with correct permissions
- [ ] IAM role trust policy includes your GitHub repo
- [ ] GitHub secrets configured (AWS_REGION, AWS_IAM_ROLE_ARN)
- [ ] Repository name matches IAM role condition
- [ ] Code committed and ready to push

**Ready to deploy! 🚀**


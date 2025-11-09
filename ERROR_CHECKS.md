# Error Checks and Troubleshooting

This workflow includes comprehensive error checks to help you diagnose issues without exposing sensitive information.

## 🔍 Error Checks Overview

### Job 1: Deploy Base Infra (ECR)

#### 1. GitHub Secrets Validation
- ✅ Checks if `AWS_REGION` secret is set
- ✅ Checks if `AWS_IAM_ROLE_ARN` secret is set
- ✅ Provides clear error messages if secrets are missing
- 🔒 **Security:** Never exposes secret values

#### 2. AWS Connection Validation
- ✅ Validates OIDC authentication
- ✅ Tests AWS connection
- ✅ Provides troubleshooting steps for OIDC errors
- 🔒 **Security:** Never exposes account IDs or credentials

#### 3. Terraform Backend Validation
- ✅ Checks if `backend.tf` exists
- ✅ Validates backend configuration structure
- ✅ Verifies S3 bucket and DynamoDB table exist
- 🔒 **Security:** Bucket/table names are not exposed in error messages

#### 4. Terraform Configuration Validation
- ✅ Validates Terraform syntax after init
- ✅ Checks for configuration errors
- ✅ Provides helpful error messages

#### 5. Terraform Apply Validation
- ✅ Checks if infrastructure creation succeeded
- ✅ Provides troubleshooting steps for common issues
- ✅ Validates IAM permissions

### Job 2: Build and Push Docker Image

#### 1. ECR Repository Validation
- ✅ Checks if ECR repository URL is available from Job 1
- ✅ Validates ECR login
- ✅ Provides troubleshooting steps for ECR access issues

#### 2. Dockerfile Validation
- ✅ Checks if Dockerfile exists
- ✅ Provides clear error if Dockerfile is missing

#### 3. Docker Build Validation
- ✅ Validates Docker build succeeded
- ✅ Validates Docker push succeeded
- ✅ Provides troubleshooting steps for build/push issues

### Job 3: Deploy App Service

#### 1. Image Tag Validation
- ✅ Checks if image tag is available from Job 2
- ✅ Validates image tag format

#### 2. Terraform Apply Validation
- ✅ Checks if App Runner service creation succeeded
- ✅ Validates health check configuration
- ✅ Provides troubleshooting steps for deployment issues

#### 3. Service URL Validation
- ✅ Retrieves and displays service URL
- ✅ Provides helpful messages if URL retrieval fails

## 🔒 Security Features

### No Credential Exposure
- ✅ Secrets are never echoed or logged
- ✅ AWS account IDs are never exposed
- ✅ Resource names are not exposed in error messages
- ✅ Only validation results are shown (✅ or ❌)

### Safe Error Messages
- ✅ Error messages provide guidance without exposing sensitive info
- ✅ Troubleshooting steps are generic and helpful
- ✅ No hardcoded account-specific information

## 📋 Common Error Scenarios

### 1. GitHub Secrets Not Set
**Error:** `AWS_REGION secret is not set`
**Solution:** 
- Go to Settings → Secrets and variables → Actions
- Add the required secrets

### 2. OIDC Authentication Failed
**Error:** `Failed to configure AWS credentials`
**Solution:**
- Check IAM role trust policy
- Verify repository name matches trust policy condition
- Check OIDC provider is configured

### 3. S3 Bucket Not Found
**Error:** `S3 bucket for Terraform state does not exist`
**Solution:**
- Create the S3 bucket specified in `terraform/backend.tf`
- Enable versioning on the bucket
- Verify IAM role has S3 permissions

### 4. DynamoDB Table Not Found
**Error:** `DynamoDB table for Terraform locking does not exist`
**Solution:**
- Create the DynamoDB table specified in `terraform/backend.tf`
- Set partition key to `LockID` (String)
- Verify IAM role has DynamoDB permissions

### 5. Terraform Init Failed
**Error:** `Terraform init failed`
**Solution:**
- Check S3 bucket and DynamoDB table exist
- Verify IAM permissions
- Check backend configuration for typos

### 6. Docker Build Failed
**Error:** `Docker build or push failed`
**Solution:**
- Check Dockerfile for syntax errors
- Verify dependencies are available
- Check ECR permissions

### 7. App Runner Deployment Failed
**Error:** `Terraform apply failed`
**Solution:**
- Check IAM role has App Runner permissions
- Verify ECR image exists
- Check health check configuration

## 🛠️ Troubleshooting Tips

1. **Check Error Messages:** Each error check provides specific troubleshooting steps
2. **Review Job Logs:** Check the failed job's logs for detailed error messages
3. **Verify Prerequisites:** Ensure all AWS resources are created before running the workflow
4. **Check IAM Permissions:** Verify the IAM role has all required permissions
5. **Validate Configuration:** Check Terraform files for syntax errors

## 📚 Additional Resources

- `SECURITY.md` - Security best practices
- `README.md` - Setup instructions
- `PREREQUISITES_CHECKLIST.md` - Prerequisites checklist

## 🔍 Error Check Locations

All error checks are marked with 🔍 emoji in the workflow logs for easy identification.

## ✅ Success Indicators

- ✅ Green checkmarks indicate successful validation
- ✅ Clear success messages confirm each step completed
- ✅ Service URL is displayed upon successful deployment

## ⚠️ Warnings

- ⚠️ Warnings indicate non-critical issues that should be addressed
- ⚠️ Warnings don't block the workflow but may cause issues later

## ❌ Errors

- ❌ Red X marks indicate failures
- ❌ Error messages provide specific troubleshooting steps
- ❌ Workflow stops on errors to prevent further issues

---

**Note:** All error checks are designed to be helpful without exposing sensitive information. If you encounter an error not covered here, check the workflow logs for detailed error messages.


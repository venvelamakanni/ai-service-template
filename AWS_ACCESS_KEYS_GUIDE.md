# AWS Access Keys Guide

## Important: GitHub Actions Uses OIDC (No Access Keys Needed!)

**For GitHub Actions CI/CD:** You do **NOT** need AWS Access Keys. The workflow uses **OIDC (OpenID Connect)** authentication, which is more secure and doesn't require storing access keys in GitHub Secrets.

**GitHub Secrets needed:**
- ✅ `AWS_REGION` (e.g., `us-east-1`)
- ✅ `AWS_IAM_ROLE_ARN` (e.g., `arn:aws:iam::123456789012:role/github-actions-role`)
- ❌ ~~`AWS_ACCESS_KEY_ID`~~ (NOT needed)
- ❌ ~~`AWS_SECRET_ACCESS_KEY`~~ (NOT needed)

---

## When You DO Need Access Keys

You only need AWS Access Keys if you want to:
1. Run AWS CLI commands locally (e.g., run the `check-prerequisites.sh` script)
2. Test Terraform locally before pushing to GitHub
3. Access AWS services from your local machine

---

## How to Create AWS Access Keys

### Step 1: Log into AWS Console
1. Go to: https://console.aws.amazon.com/
2. Sign in with your AWS account

### Step 2: Navigate to IAM
1. Search for "IAM" in the top search bar
2. Click on "IAM" service

### Step 3: Go to Users
1. In the left sidebar, click **"Users"**
2. Click on your username (or create a new user if needed)

### Step 4: Create Access Key
1. Click on the **"Security credentials"** tab
2. Scroll down to **"Access keys"** section
3. Click **"Create access key"** button

### Step 5: Choose Use Case
1. Select **"Command Line Interface (CLI)"** as the use case
2. Check the confirmation box
3. Click **"Next"**

### Step 6: (Optional) Add Description
1. Add a description tag (e.g., "Local development")
2. Click **"Create access key"**

### Step 7: Save Your Keys
**⚠️ IMPORTANT: Save these keys immediately! You won't be able to see the secret key again.**

1. **Access Key ID**: Copy this value (e.g., `AKIAIOSFODNN7EXAMPLE`)
2. **Secret Access Key**: Copy this value (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
3. Click **"Done"**

**Store these securely:**
- Never commit them to git
- Never share them publicly
- Consider using a password manager

---

## Configure AWS CLI with Access Keys

### Option 1: Using `aws configure` (Recommended)

```bash
aws configure
```

You'll be prompted for:
1. **AWS Access Key ID**: Paste your access key ID
2. **AWS Secret Access Key**: Paste your secret access key
3. **Default region name**: Enter your region (e.g., `us-east-1`)
4. **Default output format**: Press Enter for `json` (or enter `text` or `table`)

### Option 2: Using Environment Variables

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

### Option 3: Using AWS Credentials File

Create/edit `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Create/edit `~/.aws/config`:
```ini
[default]
region = us-east-1
output = json
```

---

## Verify Your Access Keys

Test that your access keys work:

```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

## IAM Permissions Needed

For the access keys to work with this project, the IAM user needs these permissions:

### Minimum Required Policies:
- `AmazonS3FullAccess` (for Terraform state)
- `AmazonDynamoDBFullAccess` (for Terraform lock table)
- `AWSAppRunnerFullAccess` (for App Runner service)
- `AmazonEC2ContainerRegistryFullAccess` (for ECR)
- `IAMFullAccess` (for creating App Runner IAM role)

### Or Create a Custom Policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "dynamodb:*",
                "apprunner:*",
                "ecr:*",
                "iam:*"
            ],
            "Resource": "*"
        }
    ]
}
```

**Note:** For production, use least-privilege principles and restrict resources to specific ARNs.

---

## Security Best Practices

### 1. Never Commit Access Keys
Add to `.gitignore`:
```
.aws/
*.pem
*.key
.env
```

### 2. Rotate Keys Regularly
- Rotate access keys every 90 days
- Delete unused access keys

### 3. Use IAM Roles When Possible
- For EC2 instances: Use IAM roles (no access keys needed)
- For GitHub Actions: Use OIDC (no access keys needed)
- For local development: Access keys are okay, but rotate regularly

### 4. Use Different Keys for Different Environments
- Development keys
- Production keys (with stricter permissions)
- CI/CD keys (for services that can't use OIDC)

### 5. Monitor Key Usage
- Enable CloudTrail to track access key usage
- Set up alerts for unusual activity

---

## Troubleshooting

### Error: "Unable to locate credentials"
**Solution:** Configure AWS CLI with `aws configure`

### Error: "Access Denied"
**Solution:** Check IAM user permissions. The user needs the policies listed above.

### Error: "InvalidAccessKeyId"
**Solution:** 
- Verify the access key ID is correct
- Check if the access key was deleted
- Create a new access key

### Error: "SignatureDoesNotMatch"
**Solution:**
- Verify the secret access key is correct
- Check for extra spaces or characters
- Create a new access key if needed

---

## Quick Reference

### Where to Find Access Keys:
1. AWS Console → IAM → Users → Your User → Security credentials → Access keys

### Where to Configure:
```bash
aws configure
```

### Where Keys Are Stored:
- Linux/Mac: `~/.aws/credentials` and `~/.aws/config`
- Windows: `C:\Users\USERNAME\.aws\credentials` and `C:\Users\USERNAME\.aws\config`

### Test Configuration:
```bash
aws sts get-caller-identity
```

---

## Summary

- **GitHub Actions**: ❌ No access keys needed (uses OIDC)
- **Local AWS CLI**: ✅ Access keys needed (for local testing)
- **Location**: AWS Console → IAM → Users → Security credentials
- **Security**: Never commit keys, rotate regularly, use least privilege

---

## Next Steps

1. **For GitHub Actions**: Skip access keys, just set up OIDC (see PREREQUISITES_CHECKLIST.md)
2. **For Local Testing**: Create access keys and run `aws configure`
3. **Verify**: Run `aws sts get-caller-identity` to test
4. **Run Prerequisites Check**: Execute `./check-prerequisites.sh` to verify setup


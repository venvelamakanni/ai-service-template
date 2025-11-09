# OIDC Troubleshooting Guide

## Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

This error occurs when GitHub Actions tries to assume your IAM role using OIDC but is denied. Here's how to fix it.

---

## Step-by-Step Fix

### Step 1: Verify OIDC Provider Exists

1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/
2. Click **"Identity providers"** in the left sidebar
3. Look for: `token.actions.githubusercontent.com`
4. If it doesn't exist, create it:
   - Click **"Add provider"**
   - Select **"OpenID Connect"**
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
   - Click **"Get thumbprint"** (auto-fetches)
   - Click **"Add provider"**

---

### Step 2: Check IAM Role Trust Policy

The trust policy must allow GitHub Actions to assume the role.

1. Go to AWS IAM Console → **Roles**
2. Find your role (e.g., `github-actions-role`)
3. Click on the role name
4. Click the **"Trust relationships"** tab
5. Click **"Edit trust policy"**

### Correct Trust Policy Format:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

### Important Replacements:

1. **YOUR_ACCOUNT_ID**: Replace with your 12-digit AWS account ID
   - Find it: `aws sts get-caller-identity --query Account --output text`
   - Or: AWS Console → Your username (top right) → Account ID

2. **YOUR_GITHUB_USERNAME**: Your GitHub username or organization name
   - Example: `bharadwajvvs`

3. **YOUR_REPO_NAME**: Your GitHub repository name
   - Example: `ai-service-template`

### Example Trust Policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:bharadwajvvs/ai-service-template:*"
        }
      }
    }
  ]
}
```

---

### Step 3: Verify OIDC Provider ARN Format

The OIDC provider ARN format must match exactly:

**Correct format:**
```
arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

**Common mistakes:**
- ❌ Missing `oidc-provider/` prefix
- ❌ Wrong account ID
- ❌ Extra spaces or typos

### How to Get Your OIDC Provider ARN:

1. Go to IAM → Identity providers
2. Click on `token.actions.githubusercontent.com`
3. Copy the **Provider ARN** (looks like: `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`)

---

### Step 4: Verify GitHub Repository Path

The condition in the trust policy must match your GitHub repository exactly.

**Format:**
```
repo:USERNAME/REPO_NAME:*
```

**Examples:**
- ✅ `repo:bharadwajvvs/ai-service-template:*` (all branches)
- ✅ `repo:myorg/ai-service-template:*` (organization repo)
- ✅ `repo:bharadwajvvs/ai-service-template:ref:refs/heads/main` (specific branch)

**Common mistakes:**
- ❌ Wrong username (case-sensitive)
- ❌ Wrong repository name (case-sensitive)
- ❌ Missing `:*` at the end (if you want all branches)
- ❌ Extra spaces

**How to verify:**
- Go to your GitHub repository
- Check the URL: `https://github.com/USERNAME/REPO_NAME`
- Use exactly: `repo:USERNAME/REPO_NAME:*`

---

### Step 5: Verify GitHub Secrets

Check that your GitHub secrets are set correctly:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Verify these secrets exist:

   - **AWS_REGION**: Should be your AWS region (e.g., `us-east-1`)
   - **AWS_IAM_ROLE_ARN**: Should be the full ARN of your IAM role
     - Format: `arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME`
     - Example: `arn:aws:iam::123456789012:role/github-actions-role`

**Common mistakes:**
- ❌ Missing `arn:aws:iam::` prefix
- ❌ Wrong account ID
- ❌ Wrong role name
- ❌ Extra spaces

---

### Step 6: Test the Trust Policy

You can test if the trust policy is correct by checking the role:

```bash
aws iam get-role --role-name github-actions-role --query 'Role.AssumeRolePolicyDocument'
```

Expected output should show the trust policy with:
- Correct OIDC provider ARN
- Correct GitHub repository condition
- `sts:AssumeRoleWithWebIdentity` action

---

## Common Issues and Solutions

### Issue 1: OIDC Provider Doesn't Exist

**Error:** Trust policy references non-existent OIDC provider

**Solution:**
1. Create the OIDC provider (see Step 1)
2. Wait a few minutes for it to propagate
3. Update the trust policy with the correct provider ARN

---

### Issue 2: Wrong Repository in Trust Policy

**Error:** Repository name doesn't match

**Solution:**
1. Check your GitHub repository URL
2. Update the trust policy condition:
   ```json
   "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:*"
   ```
3. Make sure it's case-sensitive and matches exactly

---

### Issue 3: Wrong Account ID in OIDC Provider ARN

**Error:** Trust policy references wrong account

**Solution:**
1. Get your AWS account ID:
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```
2. Update the trust policy with the correct account ID:
   ```json
   "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
   ```

---

### Issue 4: Trust Policy Condition Too Restrictive

**Error:** Condition doesn't allow the GitHub Actions workflow

**Solution:**
1. For testing, you can temporarily allow all repositories:
   ```json
   "StringLike": {
     "token.actions.githubusercontent.com:sub": "repo:*/*:*"
   }
   ```
2. **⚠️ WARNING:** This is less secure. Use only for testing.
3. After confirming it works, restrict to your specific repository.

---

### Issue 5: OIDC Provider Thumbprint Issue

**Error:** Thumbprint verification fails

**Solution:**
1. Delete the OIDC provider
2. Recreate it and let AWS auto-fetch the thumbprint
3. Or manually get the thumbprint:
   ```bash
   openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -sha1 | sed 's/://g' | awk -F= '{print tolower($2)}'
   ```

---

## Quick Fix Checklist

- [ ] OIDC provider exists in AWS IAM
- [ ] OIDC provider ARN is correct in trust policy
- [ ] Trust policy allows `sts:AssumeRoleWithWebIdentity`
- [ ] Trust policy condition matches your GitHub repository
- [ ] GitHub repository path is correct (case-sensitive)
- [ ] GitHub secret `AWS_IAM_ROLE_ARN` is set correctly
- [ ] GitHub secret `AWS_REGION` is set correctly
- [ ] IAM role has required permissions attached
- [ ] No typos or extra spaces in trust policy

---

## Testing the Fix

After updating the trust policy:

1. **Wait 1-2 minutes** for changes to propagate
2. **Re-run the GitHub Actions workflow:**
   - Go to Actions tab
   - Click on the failed workflow
   - Click "Re-run all jobs"
3. **Monitor the "Configure AWS credentials" step**
4. **If it still fails:**
   - Check the error message for specific details
   - Verify the trust policy JSON is valid
   - Check CloudTrail logs for more details

---

## Getting More Details

### Check CloudTrail Logs:

1. Go to AWS CloudTrail Console
2. Click "Event history"
3. Filter by:
   - Event name: `AssumeRoleWithWebIdentity`
   - Time range: Last 1 hour
4. Look for error messages with more details

### Check IAM Role:

```bash
# Get role details
aws iam get-role --role-name github-actions-role

# Get trust policy
aws iam get-role --role-name github-actions-role --query 'Role.AssumeRolePolicyDocument' --output json
```

---

## Example: Complete Correct Setup

### 1. OIDC Provider:
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- Provider ARN: `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`

### 2. IAM Role Trust Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:bharadwajvvs/ai-service-template:*"
        }
      }
    }
  ]
}
```

### 3. GitHub Secrets:
- `AWS_REGION`: `us-east-1`
- `AWS_IAM_ROLE_ARN`: `arn:aws:iam::123456789012:role/github-actions-role`

### 4. IAM Role Permissions:
- `AWSAppRunnerFullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonS3FullAccess`
- `AmazonDynamoDBFullAccess`
- `IAMFullAccess`

---

## Still Having Issues?

If you're still getting the error after following these steps:

1. **Double-check the trust policy JSON** - Make sure it's valid JSON
2. **Verify the OIDC provider ARN** - Must match exactly
3. **Check repository name** - Must be exact (case-sensitive)
4. **Wait a few minutes** - AWS changes can take time to propagate
5. **Check CloudTrail logs** - Look for detailed error messages
6. **Try a simpler trust policy** - Temporarily allow all repos to test:
   ```json
   "StringLike": {
     "token.actions.githubusercontent.com:sub": "repo:*/*:*"
   }
   ```

---

## Next Steps

After fixing the OIDC issue:

1. ✅ Verify the workflow runs successfully
2. ✅ Check that resources are created in AWS
3. ✅ Get the service URL from Terraform outputs
4. ✅ Test the deployed service

Good luck! 🚀


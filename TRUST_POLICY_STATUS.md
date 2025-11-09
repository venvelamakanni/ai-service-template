# Trust Policy Status ✅

## Your Trust Policy is CORRECT! ✅

Your IAM role trust policy has been verified and is configured correctly:

```json
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
                    "token.actions.githubusercontent.com:sub": "repo:venvelakanni/ai-service-template:*"
                }
            }
        }
    ]
}
```

## Verification Results ✅

- ✅ Trust policy structure: **CORRECT**
- ✅ OIDC provider: **EXISTS and CORRECT**
- ✅ Repository: **MATCHES** (`repo:venvelakanni/ai-service-template:*`)
- ✅ IAM role: **EXISTS** with correct permissions
- ⚠️  IAMFullAccess: **NOT ATTACHED** (recommended to add)

## Next Steps

### 1. Add IAMFullAccess Permission (Recommended)

The Terraform configuration creates an IAM role for App Runner. To do this, the GitHub Actions role needs `IAMFullAccess`.

**Quick fix:**
1. Go to: https://console.aws.amazon.com/iam/
2. Roles → `github-actions-role`
3. Add permissions → Attach policies
4. Search for: `IAMFullAccess`
5. Attach it

### 2. Verify GitHub Secrets

Make sure these secrets are set in GitHub:
- `AWS_REGION`: `us-east-1`
- `AWS_IAM_ROLE_ARN`: `arn:aws:iam::016401511161:role/github-actions-role`

### 3. Re-run GitHub Actions Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click on the failed workflow
4. Click **"Re-run all jobs"**
5. Wait for it to complete

## If OIDC Error Persists

If you still get the OIDC error after verifying everything:

1. **Wait 2-3 minutes** - AWS changes can take time to propagate
2. **Check GitHub repository name** - Must match exactly (case-sensitive)
3. **Verify GitHub Secrets** - Make sure they're set correctly
4. **Check CloudTrail logs** - Look for detailed error messages
5. **Try a simpler trust policy** (temporary test):
   ```json
   "token.actions.githubusercontent.com:sub": "repo:*/*:*"
   ```
   ⚠️ **Warning:** Only use for testing, then restrict to your repo!

## Expected Behavior

After fixing the OIDC issue, the workflow should:
1. ✅ **Job 1**: Configure AWS credentials → **PASS**
2. ✅ **Job 1**: Deploy Base Infra (ECR) → **PASS**
3. ✅ **Job 2**: Build and Push Docker Image → **PASS**
4. ✅ **Job 3**: Deploy App Service → **PASS**

## Summary

Your trust policy is **100% correct**! 🎉

The OIDC error should be resolved. If it persists:
- Double-check GitHub secrets
- Wait for AWS changes to propagate
- Verify repository name matches exactly

Good luck! 🚀


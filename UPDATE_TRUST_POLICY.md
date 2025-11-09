# Update Trust Policy with Correct Repository Name

## ✅ Good News!

Your workflow ran successfully with the temporary trust policy (`repo:*/*:*`), which means:
- ✅ OIDC is working correctly
- ✅ IAM role is configured properly
- ✅ The issue was just the repository name condition

## Next Step: Find the Exact Repository Name

### Option 1: Check the Workflow Logs (Recommended)

I've added a debug step to your workflow that will show the exact repository name.

1. **Re-run the workflow** (or wait for the next run)
2. **Check the "🐞 Debug Repository Context" step** in Job 1
3. **Copy the exact repository name** it shows
4. **Use that in your trust policy**

### Option 2: Check Your GitHub Repository URL

1. Go to your GitHub repository
2. Check the URL in your browser
3. It should be: `https://github.com/OWNER/REPO`
4. The trust policy should use: `repo:OWNER/REPO:*`

**Example:**
- URL: `https://github.com/venvelakanni/ai-service-template`
- Trust policy: `repo:venvelakanni/ai-service-template:*`

## Update the Trust Policy

### Step 1: Get the Exact Repository Name

After running the workflow, check the debug output. It will show something like:
```
Repository: venvelakanni/ai-service-template
Full repo context: repo:venvelakanni/ai-service-template:*
```

### Step 2: Update the Trust Policy in AWS

1. **Go to AWS IAM Console:**
   - https://console.aws.amazon.com/iam/
   - Roles → `github-actions-role`
   - Trust relationships tab
   - Edit trust policy

2. **Update the repository condition:**

Replace this line:
```json
"token.actions.githubusercontent.com:sub": "repo:*/*:*"
```

With the exact repository name from the debug output:
```json
"token.actions.githubusercontent.com:sub": "repo:venvelakanni/ai-service-template:*"
```

### Step 3: Complete Trust Policy

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

**⚠️ Important:** Replace `venvelakanni/ai-service-template` with the exact repository name from your debug output!

### Step 4: Test

1. **Wait 1-2 minutes** for changes to propagate
2. **Re-run the GitHub Actions workflow**
3. **Verify it works** with the restricted trust policy

## Common Issues

### Issue 1: Case Sensitivity
- ✅ Correct: `repo:venvelakanni/ai-service-template:*`
- ❌ Wrong: `repo:Venvelakanni/Ai-Service-Template:*`

### Issue 2: Organization vs User
- If repo is under an organization: `repo:org-name/repo-name:*`
- If repo is under a user: `repo:username/repo-name:*`

### Issue 3: Fork vs Original
- If this is a fork, use the fork's repository name
- Not the original repository name

## Verification

After updating the trust policy:

1. ✅ Check the debug output shows the correct repository
2. ✅ Update trust policy with exact repository name
3. ✅ Wait 1-2 minutes
4. ✅ Re-run workflow
5. ✅ Verify it works with restricted policy

## Security Best Practices

Once you confirm it works:

1. ✅ **Restrict to specific repository** (not `repo:*/*:*`)
2. ✅ **Use exact repository name** (case-sensitive)
3. ✅ **Include `:*` at the end** (allows all branches)
4. ✅ **Test with the restricted policy** to ensure it works

## If It Still Doesn't Work

If the restricted policy doesn't work:

1. **Check the debug output** - Make sure you're using the exact repository name
2. **Verify case sensitivity** - Repository names are case-sensitive
3. **Check for typos** - Even a small typo will cause it to fail
4. **Try with just the repository name** (no organization): `repo:*/ai-service-template:*`

## Summary

1. ✅ Temporary policy worked → OIDC is configured correctly
2. 🔍 Check debug output for exact repository name
3. 📝 Update trust policy with exact repository name
4. 🧪 Test with restricted policy
5. ✅ Keep it restricted for security

Good luck! 🚀


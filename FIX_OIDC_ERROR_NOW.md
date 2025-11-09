# Fix OIDC Error - Step by Step

## Current Status
✅ Trust policy structure: **CORRECT**  
✅ OIDC provider: **EXISTS and CORRECT**  
✅ IAM role: **EXISTS**  
❌ **Still getting OIDC error**

## Most Likely Causes

### 1. Repository Name Mismatch (Most Common)
The trust policy expects: `repo:venvelakanni/ai-service-template:*`

**Check:**
- Go to your GitHub repository
- Check the exact URL: `https://github.com/venvelakanni/ai-service-template`
- Verify the repository name is exactly `ai-service-template` (case-sensitive)
- Verify the owner is exactly `venvelakanni` (case-sensitive)

### 2. Workflow Running from Wrong Repository
If this is a fork or template, the workflow might be running from a different repository context.

**Check:**
- Go to GitHub Actions → Failed workflow
- Check the "Workflow file" section
- Verify it shows the correct repository path

### 3. GitHub Secrets Not Set
The workflow needs these secrets to be set.

**Check:**
- Go to GitHub repository → Settings → Secrets and variables → Actions
- Verify these secrets exist:
  - `AWS_REGION`: `us-east-1`
  - `AWS_IAM_ROLE_ARN`: `arn:aws:iam::016401511161:role/github-actions-role`

---

## Quick Fix: Test with Less Restrictive Trust Policy

### Step 1: Update Trust Policy (Temporary Test)

1. **Go to AWS IAM Console:**
   - https://console.aws.amazon.com/iam/
   - Roles → `github-actions-role`
   - Trust relationships tab
   - Edit trust policy

2. **Replace with this (temporarily allows all repos):**

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
          "token.actions.githubusercontent.com:sub": "repo:*/*:*"
        }
      }
    }
  ]
}
```

3. **Click "Update policy"**

4. **Wait 1-2 minutes**

5. **Re-run the GitHub Actions workflow**

### Step 2: Check Result

- ✅ **If it works:** The issue is with the repository name condition
  - Check the exact repository name in GitHub
  - Update the trust policy with the correct repository name
  - Make sure it matches exactly (case-sensitive)

- ❌ **If it still fails:** The issue is elsewhere
  - Check OIDC provider thumbprint
  - Check GitHub secrets
  - Check CloudTrail logs for detailed error

### Step 3: Restrict Back to Your Repository

Once you confirm it works with `repo:*/*:*`, update it back to your specific repository:

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

**⚠️ Important:** Make sure the repository name matches exactly!

---

## Alternative: Check What GitHub is Actually Sending

If the temporary fix doesn't work, we need to see what GitHub is actually sending.

### Option 1: Check CloudTrail Logs

1. Go to AWS CloudTrail Console
2. Click "Event history"
3. Filter by:
   - Event name: `AssumeRoleWithWebIdentity`
   - Time range: Last 1 hour
4. Look for error events
5. Check the `errorMessage` field for details

### Option 2: Use AWS CLI to Check Recent Events

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 10 \
  --query 'Events[*].CloudTrailEvent' \
  --output text | jq '.'
```

---

## Common Repository Name Issues

### Issue 1: Case Sensitivity
- ✅ Correct: `repo:venvelakanni/ai-service-template:*`
- ❌ Wrong: `repo:Venvelakanni/Ai-Service-Template:*`
- ❌ Wrong: `repo:VENVELAKANNI/AI-SERVICE-TEMPLATE:*`

### Issue 2: Hyphens vs Underscores
- ✅ Correct: `ai-service-template`
- ❌ Wrong: `ai_service_template`

### Issue 3: Fork vs Original
- If this is a fork, the repository name might be different
- Check the actual repository URL in GitHub

### Issue 4: Organization vs User
- If the repo is under an organization, use the organization name
- Example: `repo:my-org/ai-service-template:*`

---

## Verify GitHub Repository

Run this to verify your repository:

1. Go to your GitHub repository
2. Check the URL in the browser
3. It should be: `https://github.com/venvelakanni/ai-service-template`
4. If it's different, update the trust policy with the correct name

---

## Final Checklist

Before trying the fix:

- [ ] Verified GitHub repository URL matches exactly
- [ ] Checked repository name is case-sensitive correct
- [ ] Verified GitHub secrets are set (AWS_REGION, AWS_IAM_ROLE_ARN)
- [ ] Waited 1-2 minutes after updating trust policy
- [ ] Tried the less restrictive trust policy (`repo:*/*:*`) to test
- [ ] Checked CloudTrail logs for detailed errors

---

## If Nothing Works

If the temporary fix with `repo:*/*:*` doesn't work, the issue is likely:

1. **OIDC Provider Thumbprint:** Delete and recreate the OIDC provider
2. **GitHub Secrets:** Double-check they're set correctly
3. **AWS Region:** Make sure the region matches in all places
4. **IAM Role Permissions:** Verify the role has all required permissions

---

## Next Steps

1. **Try the temporary fix** with `repo:*/*:*`
2. **If it works:** Update with the correct repository name
3. **If it doesn't work:** Check CloudTrail logs for detailed errors
4. **Contact support:** If nothing works, the issue might be with AWS or GitHub configuration

Good luck! 🚀


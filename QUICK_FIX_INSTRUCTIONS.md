# Quick Fix for OIDC Error

## The Problem
Error: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

This means the IAM role trust policy doesn't allow GitHub Actions to assume the role.

---

## Important Notes

⚠️ **Trust policies should NOT be committed to git**
- Trust policies are managed in AWS IAM Console
- They contain your AWS account ID (not sensitive, but not needed in repo)
- Use the instructions below to update directly in AWS Console

## Quick Fix (5 minutes)

### Step 1: Get Your GitHub Repository Info

Find your GitHub repository URL. It looks like:
```
https://github.com/YOUR_USERNAME/YOUR_REPO_NAME
```

**Example:**
- URL: `https://github.com/bharadwajvvs/ai-service-template`
- Username: `bharadwajvvs`
- Repo name: `ai-service-template`

---

### Step 2: Update IAM Role Trust Policy

1. **Go to AWS IAM Console:**
   - https://console.aws.amazon.com/iam/
   - Click **"Roles"** in the left sidebar
   - Search for: `github-actions-role`
   - Click on the role name

2. **Click "Trust relationships" tab**

3. **Click "Edit trust policy"**

4. **Replace the entire policy with this:**

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

5. **Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual values:**

**Example:**
If your repo is `https://github.com/bharadwajvvs/ai-service-template`, then:
```json
"token.actions.githubusercontent.com:sub": "repo:bharadwajvvs/ai-service-template:*"
```

6. **Click "Update policy"**

---

### Step 3: Verify GitHub Secrets

1. **Go to your GitHub repository**
2. **Click Settings → Secrets and variables → Actions**
3. **Verify these secrets exist:**

   - **AWS_REGION**: `us-east-1` (or your region)
   - **AWS_IAM_ROLE_ARN**: `arn:aws:iam::016401511161:role/github-actions-role`

4. **If secrets are missing, add them:**
   - Click "New repository secret"
   - Add each secret with the values above

---

### Step 4: Re-run the Workflow

1. **Go to GitHub Actions tab**
2. **Click on the failed workflow run**
3. **Click "Re-run all jobs"** (or "Re-run failed jobs")
4. **Wait for it to complete**

The "Configure AWS credentials" step should now pass! ✅

---

## Common Mistakes to Avoid

❌ **Wrong repository name** (case-sensitive)
- ✅ Correct: `repo:bharadwajvvs/ai-service-template:*`
- ❌ Wrong: `repo:Bharadwajvvs/Ai-Service-Template:*`

❌ **Missing `:*` at the end**
- ✅ Correct: `repo:username/repo:*`
- ❌ Wrong: `repo:username/repo`

❌ **Wrong account ID in OIDC provider ARN**
- ✅ Correct: `arn:aws:iam::016401511161:oidc-provider/...`
- ❌ Wrong: `arn:aws:iam::123456789012:oidc-provider/...`

❌ **Extra spaces or typos**
- Make sure the JSON is valid
- No extra commas
- All quotes are correct

---

## Testing After Fix

After updating the trust policy:

1. **Wait 1-2 minutes** for AWS to propagate changes
2. **Re-run the GitHub Actions workflow**
3. **Check the "Configure AWS credentials" step** - it should pass
4. **If it still fails:**
   - Double-check the repository name (case-sensitive!)
   - Verify the OIDC provider exists
   - Check GitHub secrets are set correctly

---

## Still Having Issues?

If you're still getting the error:

1. **Check the exact error message** in GitHub Actions logs
2. **Verify your GitHub repository URL** matches the trust policy
3. **Try a temporary test** - allow all repositories:
   ```json
   "token.actions.githubusercontent.com:sub": "repo:*/*:*"
   ```
   ⚠️ **Warning:** Only use this for testing, then restrict to your repo!

4. **Check CloudTrail logs** in AWS Console for more details

---

## Need Help?

If you're stuck, check:
- `OIDC_TROUBLESHOOTING.md` - Detailed troubleshooting guide
- `PREREQUISITES_CHECKLIST.md` - Complete setup checklist
- AWS IAM Console - Verify the trust policy was saved correctly

---

## Quick Checklist

- [ ] Got GitHub username and repo name
- [ ] Updated IAM role trust policy with correct repo
- [ ] Verified GitHub secrets (AWS_REGION, AWS_IAM_ROLE_ARN)
- [ ] Waited 1-2 minutes for changes to propagate
- [ ] Re-ran the GitHub Actions workflow
- [ ] Checked that "Configure AWS credentials" step passes

Good luck! 🚀


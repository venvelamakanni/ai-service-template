# Add IAMFullAccess Permission

## Why This Is Needed

The Terraform configuration creates an IAM role for App Runner to access ECR. To create IAM roles, the GitHub Actions role needs `IAMFullAccess` permission.

## Quick Fix

1. **Go to AWS IAM Console:**
   - https://console.aws.amazon.com/iam/
   - Click **"Roles"** in the left sidebar
   - Search for: `github-actions-role`
   - Click on the role name

2. **Click "Add permissions" → "Attach policies"**

3. **Search for:** `IAMFullAccess`

4. **Check the box** next to `IAMFullAccess`

5. **Click "Add permissions"**

## Verify

After adding the permission, verify it's attached:
```bash
aws iam list-attached-role-policies --role-name github-actions-role
```

You should see `IAMFullAccess` in the list.

## Alternative: More Restrictive Policy

If you want to be more secure (least privilege), you can create a custom policy that only allows creating IAM roles for App Runner:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:TagRole",
                "iam:UntagRole",
                "iam:ListRoleTags"
            ],
            "Resource": "arn:aws:iam::*:role/*-apprunner-ecr-role"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/*-apprunner-ecr-role"
        }
    ]
}
```

But for simplicity, `IAMFullAccess` works fine for this use case.


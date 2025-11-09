# Security Best Practices

## ⚠️ Important: Do Not Commit Sensitive Information

This repository should **never** contain:
- AWS Account IDs
- IAM Role ARNs with account IDs
- Trust policies with account-specific information
- Repository-specific OIDC configurations
- AWS access keys or secrets
- Terraform state files
- Any files containing your specific AWS account details

## Files That Should NOT Be Committed

The following types of files are automatically ignored (see `.gitignore`):
- Trust policy files (`*TRUST_POLICY*.md`, `*trust-policy*.sh`)
- OIDC troubleshooting files (`*OIDC*.md`, `*debug-oidc*.sh`)
- Account-specific configuration files
- Terraform state files
- AWS credentials

## Setting Up OIDC (Local Documentation Only)

When setting up OIDC for GitHub Actions:

1. **Create documentation locally** (not in the repo)
2. **Use placeholders** for account IDs and repository names
3. **Never commit** actual trust policies or account-specific configurations
4. **Use environment variables** or GitHub Secrets for sensitive values

## Trust Policy Template

If you need to create a trust policy, use this template locally (do not commit):

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Replace:**
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_USERNAME` with your GitHub username/organization
- `YOUR_REPO_NAME` with your repository name

## GitHub Secrets

Store sensitive values in GitHub Secrets (Settings → Secrets and variables → Actions):
- `AWS_REGION`: Your AWS region
- `AWS_IAM_ROLE_ARN`: Your IAM role ARN (includes account ID)

## Terraform Backend

The Terraform backend configuration in `terraform/backend.tf` contains:
- S3 bucket name (update with your bucket name)
- DynamoDB table name (update with your table name)
- Region (update with your region)

These are **not sensitive** but should be configured for your environment.

## If You Accidentally Committed Sensitive Information

1. **Remove the file** from the repository
2. **Add it to `.gitignore`** to prevent future commits
3. **Rotate any exposed credentials** (AWS keys, etc.)
4. **Check git history** - you may need to rewrite history if sensitive data was committed

## Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform Security](https://www.terraform.io/docs/language/state/sensitive-data.html)


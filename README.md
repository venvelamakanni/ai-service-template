The Production-Ready AI Service Template

This is a professional, reusable GitHub template for deploying a containerized AI or web service to the cloud with 100% automation. It uses a "Production by Default" architecture, built on the industry-standard tools of modern MLOps:

Application: FastAPI (Python)

Containerization: Docker (with multi-stage builds and non-root user)

Infrastructure as Code (IaC): Terraform (with remote state backend)

Cloud Provider: Amazon Web Services (AWS)

Deployment: GitHub Actions (with CI/CD and secure OIDC)

Compute Service: AWS App Runner (Serverless Container Service)

Container Registry: AWS Elastic Container Registry (ECR)

On every git push to the main branch, the GitHub Actions workflow will automatically provision infrastructure, build, test, and deploy your service.

🏗️ Architecture Diagram

This template implements a robust 3-job GitOps workflow to solve the "chicken-and-egg" problem of infrastructure and image dependencies.

graph TD
    A[Developer<br>(git push)] --> B{GitHub Repository};
    B --> C[GitHub Actions CI/CD];

    subgraph "Job 1: Deploy Base Infra"
        C -- triggers --> J1[Run Terraform Apply<br><i>-target=aws_ecr_repository</i>];
        J1 --> K[ECR Repo Created];
    end

    subgraph "Job 2: Build & Push"
        K -- ECR URL --> J2[Build Docker Image];
        J2 -- Pushes image to --> K;
        J2 --> L[Image Tag Created];
    end

    subgraph "Job 3: Deploy App Service"
        L -- Image Tag --> J3[Run Terraform Apply<br><i>(Full)</i>];
        J3 -- Provisions/Updates --> M[AWS App Runner];
        M -- Pulls new image --> K;
        M --> N[Service is Live! 🚀];
    end


🚀 How to Use This Template

Follow these steps precisely to get your own automated deployment pipeline.

Step 0: Prerequisites (One-Time AWS Setup)

This template requires a Terraform Remote Backend for professional-grade state management. You must create this in AWS one time. You can reuse this for all your future projects.

Create an S3 Bucket:

Go to the AWS S3 console.

Create a new, private bucket. It must have a globally unique name (e..g., yourname-terraform-state-2025).

Enable versioning on it.

Create a DynamoDB Table:

Go to the AWS DynamoDB console.

Click "Create table".

Table name: terraform-lock-table

Partition key: LockID (string)

Leave all other settings as default and create the table.

Step 1: Create Your Repository

Click the "Use this template" button at the top of this page (or create a new, empty repository) in your GitHub account.

Step 2: Configure AWS & GitHub OpenID Connect (OIDC)

This is the modern, secure, and keyless way to authenticate your CI/CD pipeline.

In AWS (IAM -> Identity providers):

Add a new OpenID Connect provider.

Provider URL: https://token.actions.githubusercontent.com

Audience: sts.amazonaws.com

Click "Get thumbprint".

In AWS (IAM -> Roles):

Create a new role.

Trusted entity type: "Web identity".

Identity Provider: Select the token.actions.githubusercontent.com provider you just created.

Audience: Select sts.amazonaws.com

For "GitHub organization/repository", enter your-github-username/your-new-repo-name.

Attach the following AWS-managed policies:

AWSAppRunnerFullAccess

AmazonEC2ContainerRegistryFullAccess

AmazonS3FullAccess (For the Terraform state)

AmazonDynamoDBFullAccess (For the Terraform lock table)

Name the role (e.g., github-actions-role). Copy its ARN.

Step 3: Update Your Terraform Configuration

In your new repository, edit the terraform/backend.tf file:

# terraform/backend.tf

terraform {
  backend "s3" {
    # UPDATE THIS:
    bucket = "yourname-terraform-state-2025"

    # UPDATE THIS:
    region = "us-east-1"

    # UPDATE THIS:
    dynamodb_table = "terraform-lock-table"

    # --- No changes needed below ---
    key     = "ai-service-template/terraform.tfstate"
    encrypt = true
  }
}


Commit and push this one change.

Step 4: Add GitHub Repository Secrets

In your new GitHub repository, go to Settings -> Secrets and variables -> Actions and add the following repository secrets:

AWS_ACCOUNT_ID: Your 12-digit AWS account number.

AWS_IAM_ROLE_ARN: The full ARN of the IAM role you created in Step 2 (e.g., arn:aws:iam::123456789012:role/github-actions-role).

AWS_REGION: The AWS region you are deploying to (e.g., us-east-1).

Step 5: Deploy!

The push you just made in Step 3 will have already triggered the workflow.

Go to the "Actions" tab in your repository.

You will see the workflow running.

Watch as Job 1, Job 2, and Job 3 execute in order.

When it finishes, click on the "3. Deploy App Service" job and expand the "Terraform Apply" step.

Scroll to the bottom of the log. You will see the service_url output.

Congratulations! Your application is live on the internet.

📂 File Structure

.
├── .github/workflows/
│   └── deploy.yml        # The 3-job CI/CD pipeline (Infra -> Build -> Deploy)
├── terraform/
│   ├── backend.tf        # Configures remote state (S3/DynamoDB)
│   ├── main.tf           # Main IaC resources (ECR, App Runner)
│   ├── outputs.tf        # Outputs the final service URL
│   └── variables.tf      # Input variables for customization
├── Dockerfile            # Multi-stage, secure Docker build
├── main.py               # The FastAPI application (with /health check)
└── requirements.txt      # Python dependencies


🛠️ Next Steps

You're ready to build!

Add your AI model: Load your model in main.py and create a new /predict endpoint.

Add dependencies: Add libraries like torch or scikit-learn to requirements.txt

Push your changes: The workflow will automatically test, build, and deploy your new version.
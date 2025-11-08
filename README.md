# The Production-Ready AI Service Template

[![Deploy to AWS](https://img.shields.io/badge/Deploy%20to-AWS-orange?logo=amazon-aws)](https://github.com/new/template?template_name=ai-service-template&owner=YOUR_USERNAME)

This is a professional, reusable GitHub template for deploying a containerized AI or web service to the cloud with 100% automation. It uses a "Production by Default" architecture, built on the industry-standard tools of modern MLOps:

* **Application:** [FastAPI](https://fastapi.tiangolo.com/) (Python)
* **Containerization:** [Docker](https://www.docker.com/) (with multi-stage builds and non-root user)
* **Infrastructure as Code (IaC):** [Terraform](https://www.terraform.io/) (with remote state backend)
* **Cloud Provider:** [Amazon Web Services (AWS)](https://aws.amazon.com/)
* **Deployment:** [GitHub Actions](https://github.com/features/actions) (with CI/CD and secure OIDC)
* **Compute Service:** [AWS App Runner](https://aws.amazon.com/app-runner/) (Serverless Container Service)
* **Container Registry:** [AWS Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/)

On every `git push` to the `main` branch, the GitHub Actions workflow will automatically provision infrastructure, build, test, and deploy your service.

## 🏗️ Architecture Diagram

This template implements a robust 3-job GitOps workflow to solve the "chicken-and-egg" problem of infrastructure and image dependencies.

```mermaid
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
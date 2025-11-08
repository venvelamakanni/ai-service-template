terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Helper Data
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------
# Resource 1: Elastic Container Registry (ECR)
# -----------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  name = "${var.app_name}-ecr-repo"

  tags = {
    Project = var.app_name
  }
}

# -----------------------------------------------------------------
# Resource 2: AWS App Runner Service
# -----------------------------------------------------------------
resource "aws_apprunner_service" "main" {
  service_name = "${var.app_name}-service"

  source_configuration {
    image_repository {
      image_identifier      = "${aws_ecr_repository.main.repository_url}:${var.image_tag}"
      image_repository_type = "ECR"
      image_configuration {
        port = 8080
      }
    }
    authentication_configuration {
      # This is a pre-defined role App Runner uses to access ECR
      # This assumes it exists. For a more robust setup, we'd create this role too.
      access_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AppRunnerECRAccessRole"
    }
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health" # Maps to our /health endpoint in main.py
    interval = 10
    timeout  = 5
  }

  instance_configuration {
    cpu    = "1024" # 1 vCPU
    memory = "2048" # 2 GB
  }

  tags = {
    Project = var.app_name
  }
}
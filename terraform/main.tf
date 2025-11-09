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
# Resource 1: IAM Role for App Runner to access ECR
# -----------------------------------------------------------------
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.app_name}-apprunner-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.app_name
  }
}

resource "aws_iam_role_policy" "apprunner_ecr_access" {
  name = "${var.app_name}-apprunner-ecr-policy"
  role = aws_iam_role.apprunner_ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.main.arn
      }
    ]
  })
}

# -----------------------------------------------------------------
# Resource 2: Elastic Container Registry (ECR)
# -----------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  name = "${var.app_name}-ecr-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

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
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
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
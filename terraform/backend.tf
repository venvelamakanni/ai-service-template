# Configures Terraform to store its state file remotely in S3.
terraform {
  backend "s3" {
    bucket = "my-architect-terraform-state-2025"

    key = "ai-service-template/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
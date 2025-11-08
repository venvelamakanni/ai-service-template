variable "aws_region" {
  description = "The AWS region to deploy all resources."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "The name for the application (used to name resources)."
  type        = string
  default     = "ai-service"
}

variable "image_tag" {
  description = "The Docker image tag to deploy (set by CI/CD)."
  type        = string
}
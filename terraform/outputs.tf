output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "service_url" {
  description = "The public, load-balanced URL of the deployed service."
  value       = aws_apprunner_service.main.service_url
}
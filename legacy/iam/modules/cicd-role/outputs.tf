###############################################################################
### CI/CD Role 모듈 출력값
###############################################################################

output "role_arn" {
  description = "GitHub Actions CI/CD IAM Role ARN"
  value       = aws_iam_role.cicd_role.arn
}

output "role_name" {
  description = "GitHub Actions CI/CD IAM Role 이름"
  value       = aws_iam_role.cicd_role.name
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC Provider ARN"
  value       = local.oidc_provider_arn
}

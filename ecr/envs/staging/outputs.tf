### =============================================================================
### envs/staging/outputs.tf
### 스테이징(staging) 환경 출력값 정의
### =============================================================================

output "app_repository_url" {
  description = "staging 환경 app ECR 레포지토리 URL"
  value       = module.app_repo.repository_url
}

output "app_repository_arn" {
  description = "staging 환경 app ECR 레포지토리 ARN"
  value       = module.app_repo.repository_arn
}

output "api_repository_url" {
  description = "staging 환경 api ECR 레포지토리 URL"
  value       = module.api_repo.repository_url
}

output "api_repository_arn" {
  description = "staging 환경 api ECR 레포지토리 ARN"
  value       = module.api_repo.repository_arn
}

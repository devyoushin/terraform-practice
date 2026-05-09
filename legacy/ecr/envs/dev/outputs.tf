### =============================================================================
### envs/dev/outputs.tf
### 개발(dev) 환경 출력값 정의
### =============================================================================

### -----------------------------------------------------------------------------
### app 레포지토리 출력값
### -----------------------------------------------------------------------------
output "app_repository_url" {
  description = "dev 환경 app ECR 레포지토리 URL"
  value       = module.app_repo.repository_url
}

output "app_repository_arn" {
  description = "dev 환경 app ECR 레포지토리 ARN"
  value       = module.app_repo.repository_arn
}

### -----------------------------------------------------------------------------
### api 레포지토리 출력값
### -----------------------------------------------------------------------------
output "api_repository_url" {
  description = "dev 환경 api ECR 레포지토리 URL"
  value       = module.api_repo.repository_url
}

output "api_repository_arn" {
  description = "dev 환경 api ECR 레포지토리 ARN"
  value       = module.api_repo.repository_arn
}

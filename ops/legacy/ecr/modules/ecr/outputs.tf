### =============================================================================
### modules/ecr/outputs.tf
### ECR 모듈 출력값 정의
### =============================================================================

output "repository_name" {
  description = "ECR 레포지토리 이름. docker push/pull 명령어에서 사용됩니다."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ECR 레포지토리 ARN. IAM 정책에서 접근 권한을 부여할 때 사용합니다."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "ECR 레포지토리 URL. 이미지 푸시/풀 시 사용합니다. (예: 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "ECR 레지스트리 ID (AWS 계정 ID). docker login 명령어에서 사용됩니다."
  value       = aws_ecr_repository.this.registry_id
}

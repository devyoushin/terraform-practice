### =============================================================================
### bootstrap/outputs.tf
### =============================================================================

output "tfstate_bucket_name" {
  description = "Terraform 상태 저장 S3 버킷 이름 (terragrunt.hcl의 bucket 값과 일치해야 함)"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_lock_table_name" {
  description = "Terraform 상태 잠금 DynamoDB 테이블 이름 (terragrunt.hcl의 dynamodb_table 값과 일치해야 함)"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "next_steps" {
  description = "다음 단계 안내"
  value       = <<-EOT
    부트스트랩 완료! 이제 Terragrunt를 사용할 수 있습니다.

    1. 단일 모듈 실행:
       cd ../dev/vpc
       terragrunt init
       terragrunt plan

    2. 환경 전체 실행 (의존성 순서 자동 처리):
       terragrunt run-all plan  --terragrunt-working-dir ../dev/
       terragrunt run-all apply --terragrunt-working-dir ../dev/
  EOT
}

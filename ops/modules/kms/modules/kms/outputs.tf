### =============================================================================
### modules/kms/outputs.tf
### KMS 모듈 출력값 정의
### =============================================================================

output "key_id" {
  description = "KMS 키 ID. aws_kms_key 리소스의 key_id 속성과 동일합니다."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "KMS 키 ARN. S3, RDS, EBS 등 다른 리소스의 kms_key_arn 변수에 전달하여 암호화를 활성화합니다."
  value       = aws_kms_key.this.arn
}

output "key_alias" {
  description = "KMS 키 별칭 이름. (예: alias/my-project-prod-rds)"
  value       = aws_kms_alias.this.name
}

output "key_alias_arn" {
  description = "KMS 키 별칭 ARN."
  value       = aws_kms_alias.this.arn
}

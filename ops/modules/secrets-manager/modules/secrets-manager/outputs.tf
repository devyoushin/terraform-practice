### =============================================================================
### modules/secrets-manager/outputs.tf
### =============================================================================

output "secret_id" {
  description = "시크릿 ID (이름). GetSecretValue API 호출 시 사용됩니다."
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "시크릿 ARN. IAM 정책 및 애플리케이션 코드에서 참조 시 사용합니다."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "시크릿 이름."
  value       = aws_secretsmanager_secret.this.name
}

output "secret_version_id" {
  description = "현재 시크릿 버전 ID. secret_string 지정 시에만 값이 존재합니다."
  value       = length(aws_secretsmanager_secret_version.this) > 0 ? aws_secretsmanager_secret_version.this[0].version_id : null
}

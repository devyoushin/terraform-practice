### ============================================================
### modules/backup/outputs.tf
### AWS Backup 모듈 출력값 정의
### ============================================================

### 백업 볼트 정보

output "backup_vault_arn" {
  description = "백업 볼트 ARN"
  value       = aws_backup_vault.this.arn
}

output "backup_vault_name" {
  description = "백업 볼트 이름"
  value       = aws_backup_vault.this.name
}

### 백업 플랜 정보

output "backup_plan_id" {
  description = "백업 플랜 ID"
  value       = aws_backup_plan.this.id
}

output "backup_plan_arn" {
  description = "백업 플랜 ARN"
  value       = aws_backup_plan.this.arn
}

### IAM 역할 정보

output "backup_iam_role_arn" {
  description = "AWS Backup 서비스 IAM 역할 ARN"
  value       = aws_iam_role.backup.arn
}

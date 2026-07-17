### =============================================================================
### modules/organization/outputs.tf
### AWS Organizations 출력값
### =============================================================================

output "root_ou_ids" {
  description = "Root 하위 OU ID"
  value       = { for key, ou in aws_organizations_organizational_unit.root : key => ou.id }
}

output "child_ou_ids" {
  description = "2단계 OU ID"
  value       = { for key, ou in aws_organizations_organizational_unit.child : key => ou.id }
}

output "account_ids" {
  description = "생성된 AWS 계정 ID"
  value       = { for key, account in aws_organizations_account.this : key => account.id }
}

output "account_arns" {
  description = "생성된 AWS 계정 ARN"
  value       = { for key, account in aws_organizations_account.this : key => account.arn }
}

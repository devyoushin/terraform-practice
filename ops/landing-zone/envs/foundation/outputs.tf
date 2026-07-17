### =============================================================================
### envs/foundation/outputs.tf
### Landing Zone foundation 출력값
### =============================================================================

output "root_ou_ids" {
  description = "Root 하위 OU ID"
  value       = module.organization.root_ou_ids
}

output "child_ou_ids" {
  description = "2단계 OU ID"
  value       = module.organization.child_ou_ids
}

output "account_ids" {
  description = "생성된 AWS 계정 ID"
  value       = module.organization.account_ids
}

output "network_plan" {
  description = "서비스별 CIDR 할당표"
  value       = module.network_cidr_plan.service_plan
}

output "dev_cidrs" {
  description = "서비스별 dev CIDR"
  value       = module.network_cidr_plan.dev_cidrs
}

output "stg_cidrs" {
  description = "서비스별 stg CIDR"
  value       = module.network_cidr_plan.stg_cidrs
}

output "prd_cidrs" {
  description = "서비스별 prd CIDR"
  value       = module.network_cidr_plan.prd_cidrs
}

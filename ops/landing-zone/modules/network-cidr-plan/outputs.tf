### =============================================================================
### modules/network-cidr-plan/outputs.tf
### 서비스별 네트워크 CIDR 계획 출력값
### =============================================================================

output "base_cidr" {
  description = "Public cloud 전체 CIDR"
  value       = var.base_cidr
}

output "service_plan" {
  description = "서비스별 /24 및 환경별 /26 CIDR 계획"
  value       = local.service_plan
}

output "dev_cidrs" {
  description = "서비스별 dev CIDR"
  value       = { for key, plan in local.service_plan : key => plan.dev_cidr }
}

output "stg_cidrs" {
  description = "서비스별 stg CIDR"
  value       = { for key, plan in local.service_plan : key => plan.stg_cidr }
}

output "prd_cidrs" {
  description = "서비스별 prd CIDR"
  value       = { for key, plan in local.service_plan : key => plan.prd_cidr }
}

### =============================================================================
### envs/dev/main.tf - 개발(dev) 환경 WAF 구성
###
### [환경 특성]
### - managed_rules_action = "count" : 차단 없이 모니터링만 (오탐 방지)
### - enable_rate_limiting = false   : 개발 중 요청 수 제한 없음
### - resource_arn 설정 후 ALB 연결 가능
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

module "waf" {
  source = "../../modules/waf"

  project_name         = var.project_name
  environment          = "dev"
  scope                = "REGIONAL"
  default_action       = "allow"
  managed_rules_action = "count"
  enable_rate_limiting = false
  resource_arn         = var.alb_arn

  common_tags = local.common_tags
}

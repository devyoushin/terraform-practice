### =============================================================================
### envs/prod/main.tf - 운영(prod) 환경 WAF 구성
###
### [환경 특성]
### - managed_rules_action = "none" : 실제 악성 트래픽 차단
### - enable_rate_limiting = true   : DDoS 방어를 위한 IP별 요청 제한
### - rate_limit = 2000             : 5분당 IP별 최대 2000 요청
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "infra-team" }
}

module "waf" {
  source = "../../modules/waf"

  project_name         = var.project_name
  environment          = "prod"
  scope                = "REGIONAL"
  default_action       = "allow"
  managed_rules_action = "none"
  enable_rate_limiting = true
  rate_limit           = var.rate_limit
  resource_arn         = var.alb_arn

  common_tags = local.common_tags
}

### envs/staging/main.tf - WAF 스테이징 환경

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

module "waf" {
  source               = "../../modules/waf"
  project_name         = var.project_name
  environment          = "staging"
  scope                = "REGIONAL"
  default_action       = "allow"
  managed_rules_action = "none"
  enable_rate_limiting = true
  rate_limit           = 5000
  resource_arn         = var.alb_arn
  common_tags          = local.common_tags
}

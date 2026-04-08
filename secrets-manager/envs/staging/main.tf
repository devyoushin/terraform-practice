### envs/staging/main.tf - 스테이징 환경 Secrets Manager

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

module "rds_secret" {
  source = "../../modules/secrets-manager"
  project_name            = var.project_name
  environment             = "staging"
  secret_suffix           = "rds"
  description             = "RDS 데이터베이스 접속 정보"
  recovery_window_in_days = 7
  common_tags             = local.common_tags
}

module "app_secret" {
  source = "../../modules/secrets-manager"
  project_name            = var.project_name
  environment             = "staging"
  secret_suffix           = "app-config"
  description             = "애플리케이션 설정 시크릿"
  recovery_window_in_days = 7
  common_tags             = local.common_tags
}

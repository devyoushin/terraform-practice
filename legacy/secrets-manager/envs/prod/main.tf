### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 Secrets Manager 구성
###
### [환경 특성]
### - recovery_window_in_days = 30 : 실수로 인한 시크릿 삭제 방지 (최대 복구 기간)
### - kms_key_arn                  : prod 환경에서는 고객 관리형 KMS 키로 암호화
### - 자동 교체                    : 필요 시 enable_rotation=true와 rotation_lambda_arn 설정
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

module "rds_secret" {
  source = "../../modules/secrets-manager"

  project_name  = var.project_name
  environment   = "prod"
  secret_suffix = "rds"
  description   = "RDS 데이터베이스 접속 정보"

  kms_key_arn             = var.kms_key_arn
  recovery_window_in_days = 30

  common_tags = local.common_tags
}

module "app_secret" {
  source = "../../modules/secrets-manager"

  project_name  = var.project_name
  environment   = "prod"
  secret_suffix = "app-config"
  description   = "애플리케이션 설정 시크릿 (API 키, JWT 시크릿 등)"

  kms_key_arn             = var.kms_key_arn
  recovery_window_in_days = 30

  common_tags = local.common_tags
}

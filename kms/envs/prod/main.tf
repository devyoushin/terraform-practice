### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 KMS 키 구성
###
### [환경 특성]
### - deletion_window_in_days = 30 : 실수로 인한 키 삭제 방지 (최대 대기 기간)
### - enable_key_rotation = true   : 규정 준수를 위한 연간 자동 키 교체
### - multi_region = false         : 필요 시 true로 변경하여 다른 리전 복제 가능
### ⚠️ KMS 키 삭제 시 해당 키로 암호화된 데이터는 영구적으로 복호화 불가
### =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

module "rds_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "prod"
  key_suffix              = "rds"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  common_tags = local.common_tags
}

module "s3_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "prod"
  key_suffix              = "s3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  common_tags = local.common_tags
}

module "eks_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "prod"
  key_suffix              = "eks"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  common_tags = local.common_tags
}

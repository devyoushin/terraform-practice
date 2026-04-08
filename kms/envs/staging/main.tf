### =============================================================================
### envs/staging/main.tf
### 스테이징(staging) 환경 KMS 키 구성
###
### [환경 특성]
### - deletion_window_in_days = 14 : 스테이징 환경 중간 수준 보호
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
      Environment = "staging"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "staging"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

module "rds_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "staging"
  key_suffix              = "rds"
  deletion_window_in_days = 14

  common_tags = local.common_tags
}

module "s3_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "staging"
  key_suffix              = "s3"
  deletion_window_in_days = 14

  common_tags = local.common_tags
}

module "eks_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "staging"
  key_suffix              = "eks"
  deletion_window_in_days = 14

  common_tags = local.common_tags
}

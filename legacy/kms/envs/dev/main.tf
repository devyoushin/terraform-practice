### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 KMS 키 구성
###
### [환경 특성]
### - deletion_window_in_days = 7  : 개발 환경에서 빠른 키 삭제 허용 (최소값)
### - enable_key_rotation = true   : 보안을 위해 모든 환경에서 자동 키 교체 활성화
### - multi_region = false         : 개발 환경에서는 단일 리전 사용 (비용 절감)
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
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

### -----------------------------------------------------------------------------
### RDS 암호화 키
### 용도: RDS 데이터베이스 스토리지 암호화
### -----------------------------------------------------------------------------
module "rds_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "dev"
  key_suffix              = "rds"
  deletion_window_in_days = 7

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### S3 암호화 키
### 용도: S3 버킷 서버 사이드 암호화
### -----------------------------------------------------------------------------
module "s3_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "dev"
  key_suffix              = "s3"
  deletion_window_in_days = 7

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### EKS 암호화 키
### 용도: EKS Secret 리소스 암호화
### -----------------------------------------------------------------------------
module "eks_key" {
  source = "../../modules/kms"

  project_name            = var.project_name
  environment             = "dev"
  key_suffix              = "eks"
  deletion_window_in_days = 7

  common_tags = local.common_tags
}

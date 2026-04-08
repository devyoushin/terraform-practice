### =============================================================================
### envs/staging/main.tf
### 스테이징(staging) 환경 S3 버킷 구성
###
### [환경 특성]
### - force_destroy = false : 실수로 인한 데이터 손실 방지 (prod와 동일한 안전 설정)
### - enable_versioning = true : prod와 동일한 조건으로 검증하기 위해 버전관리 활성화
### - 수명주기 규칙 부분 적용 : logs 버킷에만 적용하여 prod와 유사한 환경 구성
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

### -----------------------------------------------------------------------------
### 공통 태그 정의
### -----------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "staging"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### 정적 파일(assets) 버킷
### 용도: 프론트엔드 빌드 결과물, 이미지, CSS, JS 등 정적 리소스 저장
### staging 특이사항: prod와 동일하게 버전관리 활성화하여 롤백 가능
### -----------------------------------------------------------------------------
module "assets_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "staging"
  bucket_suffix = "assets"

  # staging 환경: prod와 동일하게 버전관리 활성화 (운영 환경 검증)
  enable_versioning = true
  # staging 환경: 실수로 인한 데이터 손실 방지
  force_destroy    = false
  enable_lifecycle = false

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 로그 저장 버킷
### 용도: 애플리케이션 로그, 액세스 로그 등 저장
### staging 특이사항: 수명주기 관리로 오래된 로그 자동 정리
### -----------------------------------------------------------------------------
module "logs_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "staging"
  bucket_suffix = "logs"

  # 로그는 버전관리 불필요
  enable_versioning = false
  force_destroy     = false
  # 로그는 수명주기 관리로 스토리지 비용 절감
  enable_lifecycle = true

  common_tags = local.common_tags
}

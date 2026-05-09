### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 S3 버킷 구성
###
### [환경 특성]
### - force_destroy = true  : 개발 중 버킷 재생성이 잦으므로 강제 삭제 허용
### - enable_versioning = false : 비용 절감 및 빠른 반복 개발을 위해 버전관리 비활성화
### - KMS 암호화 미사용 : S3 관리형 키(AES256) 사용으로 비용 절감
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

### -----------------------------------------------------------------------------
### 공통 태그 정의
### -----------------------------------------------------------------------------
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
### 정적 파일(assets) 버킷
### 용도: 프론트엔드 빌드 결과물, 이미지, CSS, JS 등 정적 리소스 저장
### dev 특이사항: 버전관리 불필요, 자유로운 삭제 허용
### -----------------------------------------------------------------------------
module "assets_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "dev"
  bucket_suffix = "assets"

  # dev 환경: 버전관리 불필요 (빠른 반복 배포)
  enable_versioning = false
  # dev 환경: terraform destroy 시 내용 있어도 삭제 허용
  force_destroy    = true
  enable_lifecycle = false

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 로그 저장 버킷
### 용도: 애플리케이션 로그, 액세스 로그 등 저장
### dev 특이사항: 수명주기 관리로 오래된 로그 자동 정리
### -----------------------------------------------------------------------------
module "logs_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "dev"
  bucket_suffix = "logs"

  enable_versioning = false
  force_destroy     = true
  # 로그는 수명주기 관리로 스토리지 비용 절감
  enable_lifecycle = true

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 백업 버킷 (필요 시 주석 해제)
### 용도: 데이터베이스 덤프, 스냅샷 등 백업 파일 저장
### dev 환경에서는 일반적으로 불필요하므로 기본 비활성화
### -----------------------------------------------------------------------------
# module "backup_bucket" {
#   source = "../../modules/s3"
#
#   project_name  = var.project_name
#   environment   = "dev"
#   bucket_suffix = "backup"
#
#   enable_versioning = true
#   force_destroy     = true
#   enable_lifecycle  = true
#
#   common_tags = local.common_tags
# }

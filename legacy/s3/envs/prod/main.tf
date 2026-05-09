### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 S3 버킷 구성
###
### [환경 특성]
### - force_destroy = false : 실수로 인한 데이터 손실 방지 (절대 true로 변경 금지)
### - enable_versioning = true : 모든 주요 버킷에 버전관리 활성화 (롤백 가능)
### - enable_lifecycle = true : 스토리지 비용 최적화를 위한 수명주기 규칙 적용
### - 필요 시 KMS 암호화 적용 가능 (kms_key_arn 변수 사용)
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

### -----------------------------------------------------------------------------
### 공통 태그 정의
### -----------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### 정적 파일(assets) 버킷
### 용도: 프론트엔드 빌드 결과물, 이미지, CSS, JS 등 정적 리소스 저장
### prod 특이사항: 버전관리 활성화 (실수로 삭제된 파일 복구 가능), 삭제 방지
### -----------------------------------------------------------------------------
module "assets_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "assets"

  # prod 환경: 버전관리 활성화 필수 (파일 롤백 가능)
  enable_versioning = true
  # prod 환경: 실수로 인한 데이터 손실 방지 (절대 true로 변경 금지)
  force_destroy    = false
  enable_lifecycle = false

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 로그 저장 버킷
### 용도: 애플리케이션 로그, CloudTrail 로그, ALB 액세스 로그 등 저장
### prod 특이사항: 수명주기 규칙으로 비용 최적화, 버전관리 불필요
### -----------------------------------------------------------------------------
module "logs_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "logs"

  # 로그는 버전관리 불필요
  enable_versioning = false
  force_destroy     = false
  # 로그는 수명주기 관리로 스토리지 비용 절감 (30일→STANDARD_IA, 90일→삭제)
  enable_lifecycle = true

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 백업 버킷
### 용도: 데이터베이스 스냅샷, 중요 데이터 백업 파일 저장
### prod 특이사항: 버전관리 + 수명주기 규칙으로 장기 보관 비용 최적화
### ※ 중요 데이터는 Cross-Region Replication(CRR) 고려:
###    다른 리전(예: ap-northeast-1 도쿄)에 복제하여 재해 복구(DR) 대비
###    CRR 설정은 aws_s3_bucket_replication_configuration 리소스 추가 필요
### -----------------------------------------------------------------------------
module "backup_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "backup"

  # 백업 버킷: 버전관리 필수 (이전 백업 파일 보존)
  enable_versioning = true
  force_destroy     = false
  # 수명주기 규칙으로 오래된 백업 자동 정리 (비용 최적화)
  enable_lifecycle = true

  common_tags = local.common_tags
}

### ============================================================
### envs/dev/main.tf
### 개발 환경 AWS Backup 배포 설정
### 특징: 비용 최소화, 단기 보존(7일), 콜드 스토리지 미사용
### ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

### AWS 프로바이더 설정 - 기본 태그로 모든 리소스에 공통 태그 자동 적용
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

### 공통 태그 로컬 변수
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-08"
  }
}

### Backup 모듈 호출
### dev 환경 특성:
###   - delete_after_days = 7: 최단 보존으로 비용 최소화
###   - cold_storage_after_days = null: 콜드 스토리지 미사용 (비용 절약)
###   - resource_arns: 개발 환경 백업 대상 리소스 ARN 목록
module "backup" {
  source = "../../modules/backup"

  ### 기본 정보
  project_name = var.project_name
  environment  = "dev"

  ### 볼트 설정
  vault_name  = "Default"
  kms_key_arn = null # AWS 관리형 KMS 키 사용 (비용 절약)

  ### 백업 스케줄 - 매일 UTC 새벽 3시 (KST 낮 12시)
  backup_schedule = "cron(0 3 * * ? *)"

  ### 보존 기간 - dev: 7일 (비용 최소화)
  delete_after_days       = 7
  cold_storage_after_days = null # dev: 콜드 스토리지 미사용

  ### 백업 대상 리소스
  resource_arns = var.resource_arns

  ### 태그 기반 선택 - dev: 비활성화 (명시적 ARN 지정만 사용)
  selection_tag = null

  ### 공통 태그
  common_tags = local.common_tags
}

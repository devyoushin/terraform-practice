### ============================================================
### envs/staging/main.tf
### 스테이징 환경 AWS Backup 배포 설정
### 특징: 14일 보존, 태그 기반 리소스 선택, AWS 관리형 KMS
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

### AWS 프로바이더 설정
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
    Environment = "staging"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-13"
  }
}

### Backup 모듈 호출
### staging 환경 특성:
###   - delete_after_days = 14: dev보다 긴 보존
###   - cold_storage_after_days = null: 콜드 스토리지 미사용
###   - selection_tag: 태그 기반 리소스 선택 (Backup=true 태그)
module "backup" {
  source = "../../modules/backup"

  ### 기본 정보
  project_name = var.project_name
  environment  = "staging"

  ### 볼트 설정
  vault_name  = "Default"
  kms_key_arn = null # AWS 관리형 KMS 키 사용

  ### 백업 스케줄 - 매일 UTC 새벽 3시 (KST 낮 12시)
  backup_schedule = "cron(0 3 * * ? *)"

  ### 보존 기간 - staging: 14일
  delete_after_days       = 14
  cold_storage_after_days = null

  ### 백업 대상 리소스 - staging: ARN 직접 지정 + 태그 기반 병행 사용
  resource_arns = var.resource_arns

  ### 태그 기반 선택 - Backup=true 태그를 가진 리소스 자동 포함
  selection_tag = {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }

  ### 공통 태그
  common_tags = local.common_tags
}

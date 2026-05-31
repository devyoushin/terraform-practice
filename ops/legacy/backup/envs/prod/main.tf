### ============================================================
### envs/prod/main.tf
### 운영 환경 AWS Backup 배포 설정
### 특징: 90일 보존, 콜드 스토리지 전환(30일), 고객 관리형 KMS, 태그 기반 선택
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
    Environment = "prod"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-13"
  }
}

### Backup 모듈 호출
### prod 환경 특성:
###   - delete_after_days = 90: 장기 보존 (규정 준수)
###   - cold_storage_after_days = 30: 30일 후 콜드 스토리지 전환 (비용 최적화)
###   - kms_key_arn: 고객 관리형 KMS 키 사용 (보안 강화)
###   - selection_tag: Backup=true 태그를 가진 모든 리소스 자동 백업
module "backup" {
  source = "../../modules/backup"

  ### 기본 정보
  project_name = var.project_name
  environment  = "prod"

  ### 볼트 설정 - prod: 고객 관리형 KMS 키 적용
  vault_name  = "Default"
  kms_key_arn = var.kms_key_arn

  ### 백업 스케줄 - 매일 UTC 새벽 3시 (KST 낮 12시)
  backup_schedule = "cron(0 3 * * ? *)"

  ### 보존 기간 - prod: 90일 보존, 30일 후 콜드 스토리지 전환
  delete_after_days       = 90
  cold_storage_after_days = 30

  ### 백업 대상 리소스
  resource_arns = var.resource_arns

  ### 태그 기반 선택 - Backup=true 태그를 가진 모든 리소스 자동 백업
  selection_tag = {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }

  ### 공통 태그
  common_tags = local.common_tags
}

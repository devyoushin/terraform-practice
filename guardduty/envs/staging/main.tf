### ============================================================
### envs/staging/main.tf
### 스테이징 환경 GuardDuty 배포 설정
### 특징: ONE_HOUR 발행 주기, Medium 이상 알림, 이메일 알림 활성화
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

### GuardDuty 모듈 호출
### staging 환경 특성:
###   - finding_publishing_frequency = "ONE_HOUR": 중간 수준 주기
###   - enable_s3_logs = true: S3 위협 탐지 활성화
###   - enable_kubernetes_audit_logs = false: EKS 미사용 시 비활성화
###   - enable_malware_protection = false: 비용 절약
###   - min_severity = 4: Medium 이상 알림
module "guardduty" {
  source = "../../modules/guardduty"

  ### 기본 정보
  project_name = var.project_name
  environment  = "staging"

  ### GuardDuty 탐지기 설정
  enable_guardduty             = true
  finding_publishing_frequency = "ONE_HOUR"

  ### 데이터 소스 보호
  enable_s3_logs               = true
  enable_kubernetes_audit_logs = false
  enable_malware_protection    = false

  ### 알림 설정
  alert_email  = var.alert_email
  min_severity = 4 # Medium 이상 (4-6: Medium, 7-8: High, 9-10: Critical)

  ### 필터 설정 - staging: 비활성화
  enable_filter = false

  ### 공통 태그
  common_tags = local.common_tags
}

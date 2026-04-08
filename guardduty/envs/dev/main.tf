### ============================================================
### envs/dev/main.tf
### 개발 환경 GuardDuty 배포 설정
### 특징: 비용 최소화, SIX_HOURS 발행 주기, 악성코드 탐지 비활성화
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

### GuardDuty 모듈 호출
### dev 환경 특성:
###   - finding_publishing_frequency = "SIX_HOURS": 비용 최소화 (발행 주기 최소화)
###   - enable_s3_logs = true: S3 위협 탐지 활성화 (무료)
###   - enable_kubernetes_audit_logs = false: EKS 미사용 환경
###   - enable_malware_protection = false: 개발 환경 비용 절약
###   - min_severity = 4: Medium 이상만 알림 (불필요한 알림 최소화)
module "guardduty" {
  source = "../../modules/guardduty"

  ### 기본 정보
  project_name = var.project_name
  environment  = "dev"

  ### GuardDuty 탐지기 설정
  enable_guardduty             = true
  finding_publishing_frequency = "SIX_HOURS"

  ### 데이터 소스 보호 - dev: 기본 S3 탐지만 활성화 (비용 최소화)
  enable_s3_logs               = true
  enable_kubernetes_audit_logs = false
  enable_malware_protection    = false

  ### 알림 설정
  alert_email  = var.alert_email
  min_severity = 4 # Medium 이상 (4-6: Medium, 7-8: High, 9-10: Critical)

  ### 필터 설정 - dev: 비활성화
  enable_filter = false

  ### 공통 태그
  common_tags = local.common_tags
}

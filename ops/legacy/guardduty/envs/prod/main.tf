### ============================================================
### envs/prod/main.tf
### 운영 환경 GuardDuty 배포 설정
### 특징: FIFTEEN_MINUTES 발행 주기, 전체 보호, Low 이상 알림, 신뢰 IP 필터
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

### GuardDuty 모듈 호출
### prod 환경 특성:
###   - finding_publishing_frequency = "FIFTEEN_MINUTES": 실시간에 가까운 탐지
###   - enable_s3_logs = true: S3 위협 탐지 활성화
###   - enable_kubernetes_audit_logs = true: EKS 환경 위협 탐지 (EKS 미사용 시 false)
###   - enable_malware_protection = true: EC2 악성코드 탐지 활성화
###   - min_severity = 4: Medium 이상 알림 (Low는 노이즈 가능성, 필요 시 1로 변경)
###   - enable_filter = true: 내부 보안 스캐너 IP 제외
module "guardduty" {
  source = "../../modules/guardduty"

  ### 기본 정보
  project_name = var.project_name
  environment  = "prod"

  ### GuardDuty 탐지기 설정
  enable_guardduty             = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  ### 데이터 소스 보호 - prod: 전체 활성화
  enable_s3_logs               = true
  enable_kubernetes_audit_logs = var.enable_kubernetes_audit_logs
  enable_malware_protection    = true

  ### 알림 설정
  alert_email  = var.alert_email
  min_severity = 4 # Medium 이상 (전체 알림 원하면 1로 변경)

  ### 신뢰 IP 필터 - 내부 보안 스캐너 등 알려진 IP 제외
  enable_filter      = length(var.filter_trusted_ips) > 0
  filter_trusted_ips = var.filter_trusted_ips

  ### 공통 태그
  common_tags = local.common_tags
}

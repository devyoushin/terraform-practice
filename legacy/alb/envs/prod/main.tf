###
### prod 환경 - 메인 설정
### HTTPS 강제 사용 (HTTP → HTTPS 301 리다이렉트)
### 삭제 보호 활성화, 액세스 로그 S3 저장
###
### [중요] prod 환경은 반드시 HTTPS를 사용해야 합니다.
###   - acm_certificate_arn: 기존 ACM 인증서 ARN을 terraform.tfvars에 입력하세요.
###   - enable_https_redirect = true: 모든 HTTP 요청을 HTTPS로 강제 전환합니다.
###   - enable_deletion_protection = true: 운영 ALB 실수 삭제를 방지합니다.
###

### ============================================================
### Terraform 및 Provider 설정
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

### ============================================================
### 공통 태그 (locals)
### ============================================================

locals {
  environment = "prod"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

### ============================================================
### ALB 모듈 호출
### prod 환경 특이사항:
###   - internal = false                   : 퍼블릭 ALB
###   - enable_deletion_protection = true  : 운영 환경 삭제 보호 필수
###   - create_https_listener = true       : HTTPS 리스너 필수 생성
###   - enable_https_redirect = true       : HTTP → HTTPS 301 강제 리다이렉트
###   - acm_certificate_arn               : 기존 인증서 ARN 사용 (terraform.tfvars 참고)
###   - enable_access_logs = true          : 운영 트래픽 로그 S3 저장 (감사/분석용)
### ============================================================

module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids

  # prod: 퍼블릭 ALB
  internal = false

  # prod: 삭제 보호 활성화 필수
  enable_deletion_protection = true

  # 타겟 그룹 설정
  target_type       = var.target_type
  health_check_path = var.health_check_path

  # prod: HTTPS 강제 사용
  create_https_listener = true
  enable_https_redirect = true   # HTTP(80) → HTTPS(443) 301 리다이렉트

  # prod: 기존 ACM 인증서 ARN (terraform.tfvars에서 입력)
  # 새 인증서 발급이 필요한 경우: create_acm_certificate = true, domain_name 입력
  acm_certificate_arn = var.acm_certificate_arn

  # prod: 액세스 로그 S3 저장 활성화 (감사/분석/장애 대응용)
  enable_access_logs = true
  access_logs_bucket = var.access_logs_bucket

  common_tags = local.common_tags
}

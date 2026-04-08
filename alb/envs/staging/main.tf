###
### staging 환경 - 메인 설정
### HTTP 기본 사용, 필요 시 기존 ACM 인증서로 HTTPS 활성화 가능
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
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }
}

### ============================================================
### 공통 태그 (locals)
### ============================================================

locals {
  environment = "staging"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

### ============================================================
### ALB 모듈 호출
### staging 환경 특이사항:
###   - internal = false           : 퍼블릭 ALB (QA/테스터 접근용)
###   - enable_deletion_protection = false : 스테이징은 재생성 가능
###   - create_https_listener = false      : 기본 HTTP만 사용
###   - enable_https_redirect = false      : HTTPS 리다이렉트 없음
###
### [HTTPS 활성화 방법]
###   기존 ACM 인증서가 있는 경우:
###     1. acm_certificate_arn 변수에 인증서 ARN 입력
###     2. create_https_listener = true 로 변경
###     3. enable_https_redirect = true 로 변경 (HTTP → HTTPS 강제)
###
###   새 인증서를 발급하는 경우:
###     1. create_acm_certificate = true 로 변경
###     2. domain_name 변수에 도메인 입력
###     3. Route53에서 DNS 검증 레코드 생성 후 인증서 발급 대기
###     4. create_https_listener = true 로 변경
### ============================================================

module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids

  # staging: 퍼블릭 ALB (QA 팀 접근)
  internal = false

  # staging: 삭제 보호 비활성화
  enable_deletion_protection = false

  # 타겟 그룹 설정
  target_type       = var.target_type
  health_check_path = var.health_check_path

  # staging: 기본 HTTP만 사용
  # HTTPS 활성화 시 아래 값을 수정하세요 (위 주석 참고)
  create_https_listener = false
  enable_https_redirect = false

  # 기존 인증서 ARN (HTTPS 활성화 시 입력)
  # acm_certificate_arn = var.acm_certificate_arn

  # staging: 액세스 로그 비활성화 (비용 절감)
  enable_access_logs = false

  common_tags = local.common_tags
}

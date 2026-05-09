###
### dev 환경 - 메인 설정
### HTTP만 사용 (HTTPS 비활성화), 삭제 보호 비활성화
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
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

### ============================================================
### 공통 태그 (locals)
### ============================================================

locals {
  environment = "dev"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

### ============================================================
### ALB 모듈 호출
### dev 환경 특이사항:
###   - internal = false        : 퍼블릭 ALB
###   - enable_deletion_protection = false : 개발 편의상 삭제 보호 비활성화
###   - create_https_listener = false      : HTTP만 사용 (인증서 불필요)
###   - enable_https_redirect = false      : HTTPS 리다이렉트 없음
###   - enable_access_logs = false         : 비용 절감을 위해 로그 비활성화
### ============================================================

module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids

  # dev: 퍼블릭 ALB
  internal = false

  # dev: 삭제 보호 비활성화 (개발 편의)
  enable_deletion_protection = false

  # 타겟 그룹 설정
  target_type       = var.target_type
  health_check_path = var.health_check_path

  # dev: HTTP만 사용, HTTPS 리다이렉트 없음
  create_https_listener = false
  enable_https_redirect = false

  # dev: 액세스 로그 비활성화 (비용 절감)
  enable_access_logs = false

  common_tags = local.common_tags
}

### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 Secrets Manager 구성
###
### [환경 특성]
### - recovery_window_in_days = 0 : 개발 환경에서 시크릿 즉시 삭제 허용
### - secret_string 초기값        : terraform.tfvars에서 전달하거나 콘솔에서 직접 설정
### - 자동 교체 비활성화           : 개발 환경에서는 Lambda 설정 불필요
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

### -----------------------------------------------------------------------------
### RDS 데이터베이스 접속 정보
### -----------------------------------------------------------------------------
module "rds_secret" {
  source = "../../modules/secrets-manager"

  project_name  = var.project_name
  environment   = "dev"
  secret_suffix = "rds"
  description   = "RDS 데이터베이스 접속 정보 (host, port, username, password)"

  # dev 환경: 즉시 삭제 허용 (0 = force delete)
  recovery_window_in_days = 0

  # 초기값 설정 (실제 비밀번호는 반드시 변경하세요)
  secret_string = var.rds_secret_string

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### 애플리케이션 설정 시크릿
### 용도: API 키, JWT 시크릿, OAuth 자격증명 등
### -----------------------------------------------------------------------------
module "app_secret" {
  source = "../../modules/secrets-manager"

  project_name  = var.project_name
  environment   = "dev"
  secret_suffix = "app-config"
  description   = "애플리케이션 설정 시크릿 (API 키, JWT 시크릿 등)"

  recovery_window_in_days = 0

  common_tags = local.common_tags
}

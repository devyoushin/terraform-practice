### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 ECR 레포지토리 구성
###
### [환경 특성]
### - image_tag_mutability = "IMMUTABLE" : 프로덕션 이미지 태그 변경 불가 (불변성 보장)
###   → 동일 태그로 다른 이미지가 배포되는 사고 방지
### - force_delete = false               : 실수로 인한 레포지토리 삭제 방지 (절대 true로 변경 금지)
### - tagged_image_count = 30            : 충분한 롤백 지점 확보
### - scan_on_push = true                : 취약점 스캔 필수 (보안 감사 준수)
### =============================================================================

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
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### 애플리케이션 서버 레포지토리
### prod 특이사항: 이미지 불변성 보장, 충분한 롤백 이미지 보관
### -----------------------------------------------------------------------------
module "app_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "prod"
  name_suffix  = "app"

  # prod 환경: 이미지 태그 변경 불가 (배포된 버전 추적 가능)
  image_tag_mutability = "IMMUTABLE"
  # prod 환경: 절대 true로 변경 금지
  force_delete = false
  # 최신 30개 이미지 유지 (충분한 롤백 지점)
  tagged_image_count  = 30
  untagged_image_days = 7

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### API 서버 레포지토리
### -----------------------------------------------------------------------------
module "api_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "prod"
  name_suffix  = "api"

  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tagged_image_count   = 30
  untagged_image_days  = 7

  common_tags = local.common_tags
}

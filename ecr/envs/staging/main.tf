### =============================================================================
### envs/staging/main.tf
### 스테이징(staging) 환경 ECR 레포지토리 구성
###
### [환경 특성]
### - image_tag_mutability = "IMMUTABLE" : 스테이징부터 이미지 불변성 적용 (태그 덮어쓰기 금지)
### - force_delete = false               : 실수로 인한 레포지토리 삭제 방지
### - tagged_image_count = 20            : dev보다 많은 이미지 보관 (롤백 지점 확보)
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
      Environment = "staging"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "staging"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

module "app_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "staging"
  name_suffix  = "app"

  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tagged_image_count   = 20
  untagged_image_days  = 7

  common_tags = local.common_tags
}

module "api_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "staging"
  name_suffix  = "api"

  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tagged_image_count   = 20
  untagged_image_days  = 7

  common_tags = local.common_tags
}

### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 ECR 레포지토리 구성
###
### [환경 특성]
### - image_tag_mutability = "MUTABLE"  : 개발 중 같은 태그(latest 등)로 이미지 덮어쓰기 허용
### - force_delete = true               : 개발 환경에서 자유로운 레포지토리 삭제 허용
### - tagged_image_count = 10           : 비용 절감을 위해 최신 10개 이미지만 유지
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
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

### -----------------------------------------------------------------------------
### 공통 태그 정의
### -----------------------------------------------------------------------------
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
### 애플리케이션 서버 레포지토리
### 용도: 메인 애플리케이션 서버 Docker 이미지 저장
### dev 특이사항: 태그 변경 가능, 빠른 이미지 배포 허용
### -----------------------------------------------------------------------------
module "app_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "dev"
  name_suffix  = "app"

  # dev 환경: 같은 태그로 이미지 덮어쓰기 허용 (latest 태그 반복 푸시)
  image_tag_mutability = "MUTABLE"
  # dev 환경: 자유로운 레포지토리 삭제 허용
  force_delete = true
  # dev 환경: 비용 절감을 위해 최신 10개 이미지만 유지
  tagged_image_count  = 10
  untagged_image_days = 7

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### API 서버 레포지토리
### 용도: REST API 서버 Docker 이미지 저장
### -----------------------------------------------------------------------------
module "api_repo" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = "dev"
  name_suffix  = "api"

  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tagged_image_count   = 10
  untagged_image_days  = 7

  common_tags = local.common_tags
}

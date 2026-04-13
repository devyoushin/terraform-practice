### ============================================================
### envs/staging/main.tf
### 스테이징 환경 CodePipeline 배포 설정
### 특징: Rolling 배포, 중간 컴퓨팅, 14일 로그 보존
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

### CodePipeline 모듈 호출
### staging 환경 특성:
###   - deploy_provider = "ECS": Rolling 배포 (prod 패턴 검증용)
###   - build_compute_type = "BUILD_GENERAL1_SMALL": 비용 절약
###   - artifact_bucket_force_destroy = false: staging 데이터 보호
###   - log_retention_days = 14: 중기 로그 보존
module "codepipeline" {
  source = "../../modules/codepipeline"

  ### 기본 정보
  project_name = var.project_name
  environment  = "staging"

  ### 소스 설정
  source_provider = var.source_provider
  repository_name = var.repository_name
  branch_name     = var.branch_name

  ### 빌드 설정
  build_compute_type = "BUILD_GENERAL1_SMALL"
  build_image        = "aws/codebuild/standard:7.0"
  buildspec_path     = var.buildspec_path

  ### 배포 설정 - staging: ECS Rolling 배포
  deploy_provider  = "ECS"
  ecs_cluster_name = var.ecs_cluster_name
  ecs_service_name = var.ecs_service_name

  ### 로그 및 스토리지
  log_retention_days            = 14
  artifact_bucket_force_destroy = false

  ### 공통 태그
  common_tags = local.common_tags
}

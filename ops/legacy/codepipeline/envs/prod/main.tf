### ============================================================
### envs/prod/main.tf
### 운영 환경 CodePipeline 배포 설정
### 특징: Blue/Green 배포, 중형 컴퓨팅, 90일 로그 보존
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

### CodePipeline 모듈 호출
### prod 환경 특성:
###   - deploy_provider = "CodeDeployToECS": Blue/Green 무중단 배포 (트래픽 전환 제어)
###   - build_compute_type = "BUILD_GENERAL1_MEDIUM": 빌드 속도 향상
###   - artifact_bucket_force_destroy = false: prod 아티팩트 보호
###   - log_retention_days = 90: 감사/디버깅을 위한 장기 로그 보존
module "codepipeline" {
  source = "../../modules/codepipeline"

  ### 기본 정보
  project_name = var.project_name
  environment  = "prod"

  ### 소스 설정
  source_provider = var.source_provider
  repository_name = var.repository_name
  branch_name     = var.branch_name

  ### 빌드 설정
  build_compute_type = "BUILD_GENERAL1_MEDIUM" # prod: 빌드 속도 향상
  build_image        = "aws/codebuild/standard:7.0"
  buildspec_path     = var.buildspec_path

  ### 배포 설정 - prod: CodeDeploy Blue/Green 무중단 배포
  deploy_provider   = "CodeDeployToECS"
  deploy_app_name   = var.deploy_app_name
  deploy_group_name = var.deploy_group_name

  ### 로그 및 스토리지
  log_retention_days            = 90
  artifact_bucket_force_destroy = false # prod: 아티팩트 버킷 보호

  ### 공통 태그
  common_tags = local.common_tags
}

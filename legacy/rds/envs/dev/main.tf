### ============================================================
### envs/dev/main.tf
### 개발 환경 RDS 배포 설정
### 특징: 비용 최소화, 단일 AZ, 즉시 적용, 삭제 방지 없음
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

### AWS 프로바이더 설정 - 기본 태그로 모든 리소스에 공통 태그 자동 적용
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
    Environment = "dev"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-08"
  }
}

### RDS 모듈 호출
### dev 환경 특성:
###   - db.t3.micro: 비용 최소화
###   - multi_az = false: 단일 AZ (비용 절약)
###   - deletion_protection = false: 개발 중 자유로운 삭제
###   - skip_final_snapshot = true: 삭제 시 스냅샷 생략
###   - apply_immediately = true: 변경 사항 즉시 적용
###   - enable_performance_insights = false: 비용 절약
module "rds" {
  source = "../../modules/rds"

  ### 기본 정보
  project_name = var.project_name
  environment  = "dev"

  ### 네트워크 설정
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  ### DB 설정
  db_engine         = "mysql"
  db_engine_version = "8.0"
  db_instance_class = var.db_instance_class # 기본값: db.t3.micro
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  ### 스토리지 설정
  allocated_storage     = var.allocated_storage # 기본값: 20 GiB
  max_allocated_storage = 50                    # 오토스케일링 최대 50 GiB

  ### 가용성 설정 - dev: 단일 AZ (비용 절약)
  multi_az = false

  ### 백업 설정
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  ### 삭제/스냅샷 보호 - dev: 비활성화
  deletion_protection = false
  skip_final_snapshot = true

  ### 변경 적용 - dev: 즉시 적용
  apply_immediately = true

  ### 모니터링 - dev: 비활성화 (비용 절약)
  enable_performance_insights = false

  ### 공통 태그
  common_tags = local.common_tags
}

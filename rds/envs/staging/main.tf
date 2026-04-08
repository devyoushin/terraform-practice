### ============================================================
### envs/staging/main.tf
### 스테이징 환경 RDS 배포 설정
### 특징: 프로덕션 유사 설정, 단일 AZ, 최종 스냅샷 보존
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
    Environment = "staging"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-08"
  }
}

### RDS 모듈 호출
### staging 환경 특성:
###   - db.t3.small: dev보다 상위 (프로덕션 유사 테스트)
###   - multi_az = false: 단일 AZ (비용 일부 절감)
###   - deletion_protection = false: 스테이징 환경 유연성 유지
###   - skip_final_snapshot = false: 삭제 시 스냅샷 보존 (데이터 보호)
###   - apply_immediately = false: 유지보수 창에 적용 (prod와 동일 패턴)
###   - enable_performance_insights = false: 비용 절약
module "rds" {
  source = "../../modules/rds"

  ### 기본 정보
  project_name = var.project_name
  environment  = "staging"

  ### 네트워크 설정
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  ### DB 설정
  db_engine         = "mysql"
  db_engine_version = "8.0"
  db_instance_class = var.db_instance_class # 기본값: db.t3.small
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  ### 스토리지 설정
  allocated_storage     = var.allocated_storage # 기본값: 50 GiB
  max_allocated_storage = 200                   # 오토스케일링 최대 200 GiB

  ### 가용성 설정 - staging: 단일 AZ (비용 일부 절감)
  multi_az = false

  ### 백업 설정
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  ### 삭제/스냅샷 보호 - staging: 스냅샷은 보존
  deletion_protection = false
  skip_final_snapshot = false

  ### 변경 적용 - staging: 유지보수 창에 적용 (prod 패턴 준수)
  apply_immediately = false

  ### 모니터링 - staging: 비활성화 (비용 절약)
  enable_performance_insights = false

  ### 공통 태그
  common_tags = local.common_tags
}

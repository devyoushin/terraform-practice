### ============================================================
### envs/prod/main.tf
### 프로덕션 환경 RDS 배포 설정
### 특징: 고가용성(Multi-AZ), 삭제 방지, Performance Insights, 장기 백업
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
    Environment = "prod"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-08"
  }
}

### RDS 모듈 호출
### prod 환경 특성:
###   - db.t3.medium: 프로덕션 워크로드 대응
###   - multi_az = true: 고가용성 (가용 영역 장애 대응)
###   - deletion_protection = true: 실수로 인한 삭제 방지
###   - skip_final_snapshot = false: 삭제 시 최종 스냅샷 반드시 생성
###   - apply_immediately = false: 유지보수 창에만 변경 적용 (서비스 영향 최소화)
###   - enable_performance_insights = true: 쿼리 성능 모니터링
###   - backup_retention_period = 30: 30일 백업 보존 (규정 준수)
module "rds" {
  source = "../../modules/rds"

  ### 기본 정보
  project_name = var.project_name
  environment  = "prod"

  ### 네트워크 설정
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  ### DB 설정
  db_engine         = "mysql"
  db_engine_version = "8.0"
  db_instance_class = var.db_instance_class # 기본값: db.t3.medium
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  ### 스토리지 설정
  allocated_storage     = var.allocated_storage # 기본값: 100 GiB
  max_allocated_storage = 500                   # 오토스케일링 최대 500 GiB

  ### 가용성 설정 - prod: Multi-AZ 활성화 (고가용성)
  multi_az = true

  ### 백업 설정 - prod: 30일 보존 (규정 준수)
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  ### 삭제/스냅샷 보호 - prod: 완전 보호
  deletion_protection = true
  skip_final_snapshot = false

  ### 변경 적용 - prod: 유지보수 창에만 적용 (서비스 영향 최소화)
  apply_immediately = false

  ### 모니터링 - prod: Performance Insights 활성화
  enable_performance_insights = true

  ### 공통 태그
  common_tags = local.common_tags
}

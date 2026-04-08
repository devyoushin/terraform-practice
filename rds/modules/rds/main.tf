### ============================================================
### modules/rds/main.tf
### AWS RDS 인스턴스 및 관련 리소스 정의
### ============================================================

### DB 서브넷 그룹 - 프라이빗 서브넷으로 구성
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-rds-subnet-group"
  description = "${var.project_name} ${var.environment} RDS 서브넷 그룹 (프라이빗 서브넷)"
  subnet_ids  = var.subnet_ids

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds-subnet-group"
    Environment = var.environment
  })
}

### RDS 전용 시큐리티 그룹
### 인바운드: DB 포트 허용 (MySQL 3306)
### 아웃바운드: 전체 허용
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "${var.project_name} ${var.environment} RDS 시큐리티 그룹"
  vpc_id      = var.vpc_id

  ### 인바운드 규칙 - 허용된 CIDR 블록에서 DB 포트만 허용
  ingress {
    description = "DB 포트 인바운드 허용 (MySQL)"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ### 아웃바운드 규칙 - 전체 허용
  egress {
    description = "전체 아웃바운드 허용"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

### DB 파라미터 그룹 - MySQL 8.0 기본 파라미터 설정
resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-${var.environment}-mysql80-params"
  family      = "mysql8.0"
  description = "${var.project_name} ${var.environment} MySQL 8.0 파라미터 그룹"

  ### 슬로우 쿼리 로그 활성화
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  ### 슬로우 쿼리 기준 시간 (초)
  parameter {
    name  = "long_query_time"
    value = "2"
  }

  ### 일반 쿼리 로그 활성화
  parameter {
    name  = "general_log"
    value = "1"
  }

  ### 문자셋 설정
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-mysql80-params"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

### RDS 인스턴스 본체
resource "aws_db_instance" "this" {
  ### 식별자
  identifier = "${var.project_name}-${var.environment}-rds"

  ### 엔진 설정
  engine         = var.db_engine
  engine_version = var.db_engine_version

  ### 인스턴스 클래스 (환경별 차이)
  ### dev: db.t3.micro / staging: db.t3.small / prod: db.t3.medium 이상
  instance_class = var.db_instance_class

  ### 스토리지 설정 (오토스케일링 포함)
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  ### 스토리지 암호화 - 항상 활성화
  storage_encrypted = true

  ### DB 기본 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  ### 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  ### 파라미터 그룹
  parameter_group_name = aws_db_parameter_group.this.name

  ### 가용성 설정
  ### dev/staging: false (비용 절약), prod: true (고가용성)
  multi_az = var.multi_az

  ### 백업 설정
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window

  ### 유지보수 창 설정
  maintenance_window = var.maintenance_window

  ### 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade = true

  ### 삭제 방지
  ### dev/staging: false, prod: true (실수로 인한 삭제 방지)
  deletion_protection = var.deletion_protection

  ### 최종 스냅샷 설정
  ### dev: skip=true, staging/prod: skip=false
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  ### 변경 사항 적용 시점
  ### dev: 즉시 적용, prod: 유지보수 창에만 적용
  apply_immediately = var.apply_immediately

  ### CloudWatch 로그 내보내기 (MySQL)
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  ### Performance Insights
  ### dev/staging: false, prod: true
  performance_insights_enabled = var.enable_performance_insights

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
  })
}

### 로컬 변수 - 엔진별 포트 매핑
locals {
  db_port = var.db_engine == "mysql" ? 3306 : var.db_engine == "postgres" ? 5432 : 3306
}

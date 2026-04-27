### =============================================================================
### dev/rds/terragrunt.hcl
### DEV 환경 RDS (MySQL 8.0)
###
### 역할: 애플리케이션 데이터베이스 (관계형 데이터 저장)
### DEV 특징:
###   - db.t3.micro: 최소 사양으로 비용 최소화
###   - multi_az = false: 단일 AZ (고가용성 불필요)
###   - deletion_protection = false: 자유로운 삭제
###   - skip_final_snapshot = true: 삭제 시 스냅샷 생략
###   - apply_immediately = true: 변경사항 즉시 적용 (유지보수 창 무시)
###   - enable_performance_insights = false: 비용 절약
### 의존성: vpc, kms/rds
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-11111111111111111", "subnet-11111111111111112"]
    vpc_cidr_block     = "10.10.0.0/16"
  }
}

dependency "kms_rds" {
  config_path = "../kms/rds"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_id    = "00000000-0000-0000-0000-000000000000"
    key_arn   = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
    key_alias = "alias/terraform-practice-dev-rds"
  }
}

terraform {
  source = "../../rds/modules/rds"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # RDS는 프라이빗 서브넷에 배포 (외부 직접 접근 차단)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # RDS 보안 그룹에 허용할 CIDR (VPC 내부에서만 접근)
  allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]

  # ---------------------------------------------------------------
  # 데이터베이스 엔진
  # ---------------------------------------------------------------
  db_engine         = "mysql"
  db_engine_version = "8.0"

  # ---------------------------------------------------------------
  # 인스턴스 사양
  # dev: db.t3.micro (최소 비용)
  # prod: db.t3.medium 이상 (실제 워크로드에 맞게 조정)
  # ---------------------------------------------------------------
  db_instance_class = "db.t3.micro"

  # ---------------------------------------------------------------
  # 데이터베이스 자격증명
  # 경고: 실제 비밀번호는 절대 코드에 하드코딩하지 말 것!
  # 배포 방법:
  #   export TF_VAR_db_password="실제비밀번호"
  #   또는 Secrets Manager 참조 방식 사용
  # ---------------------------------------------------------------
  db_name     = "devdb"
  db_username = "devadmin"
  db_password = "CHANGE_ME_USE_ENV_VAR" # 환경변수 TF_VAR_db_password 로 주입할 것

  # ---------------------------------------------------------------
  # 스토리지 설정
  # dev: 20 GiB 시작, 최대 50 GiB 오토스케일링
  # prod: 100 GiB 이상, 더 큰 최대값 설정
  # ---------------------------------------------------------------
  allocated_storage     = 20
  max_allocated_storage = 50

  # ---------------------------------------------------------------
  # 가용성 설정
  # dev: 단일 AZ (비용 절약)
  # prod: Multi-AZ (자동 장애조치)
  # ---------------------------------------------------------------
  multi_az = false

  # ---------------------------------------------------------------
  # 백업 설정
  # dev: 7일 보존, 새벽 3시 백업 윈도우
  # prod: 35일 보존 (최대값)
  # ---------------------------------------------------------------
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # ---------------------------------------------------------------
  # 삭제 설정
  # dev: 삭제 보호 없음, 최종 스냅샷 생략 (빠른 정리)
  # prod: deletion_protection = true, skip_final_snapshot = false
  # ---------------------------------------------------------------
  deletion_protection = false
  skip_final_snapshot = true

  # ---------------------------------------------------------------
  # 변경 적용 시점
  # dev: 즉시 (apply_immediately = true)
  # prod: 지정된 유지보수 창에 적용 (false)
  # ---------------------------------------------------------------
  apply_immediately = true

  # ---------------------------------------------------------------
  # Performance Insights
  # dev: 비활성화 (비용 절약)
  # prod: 활성화 (슬로우 쿼리 분석, 성능 최적화)
  # ---------------------------------------------------------------
  enable_performance_insights = false

  # ---------------------------------------------------------------
  # KMS 암호화 (선택적)
  # dev: KMS 모듈 출력값 참조 (구조 일관성 유지)
  # prod: 반드시 CMK 암호화 적용
  # ---------------------------------------------------------------
  kms_key_id = dependency.kms_rds.outputs.key_arn
}

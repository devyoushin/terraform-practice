### =============================================================================
### prod/rds/terragrunt.hcl
### PROD 환경 RDS — PostgreSQL 데이터베이스
###
### 역할: 프라이빗 서브넷에 배치된 관리형 관계형 데이터베이스
### PROD 특징:
###   - db_instance_class = "db.t3.medium"  (dev: db.t3.micro)
###   - multi_az = true                     (다중 AZ 자동 장애 조치)
###   - backup_retention_period = 30        (자동 백업 30일 보존)
###   - deletion_protection = true          (실수 삭제 방지)
###   - skip_final_snapshot = false         (삭제 전 최종 스냅샷 생성)
###   - apply_immediately = false           (유지 보수 창에서만 변경 적용)
###   - enable_performance_insights = true  (쿼리 성능 분석)
###   - max_allocated_storage = 500         (자동 스토리지 확장 최대 500GB)
###   - allocated_storage = 100             (초기 할당 100GB)
###
### 의존성:
###   - vpc     → 프라이빗 서브넷 ID
###   - kms/rds → 스토리지 암호화 KMS 키
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ DB 마스터 패스워드는 Secrets Manager에서 관리 (하드코딩 금지!)
### ⚠️ multi_az = true 설정은 비용이 2배 — 하지만 고가용성 필수
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_cidr_block     = "10.0.0.0/16"
  }
}

dependency "kms_rds" {
  config_path = "../kms/rds"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_id  = "00000000-0000-0000-0000-000000000000"
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

terraform {
  source = "../../rds/modules/rds"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 배치
  # 프라이빗 서브넷 3개 AZ — Multi-AZ 구성에 필수
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # ---------------------------------------------------------------
  # 데이터베이스 엔진
  # ---------------------------------------------------------------
  engine         = "postgres"
  engine_version = "15.4"
  db_name        = "appdb"

  # ---------------------------------------------------------------
  # 마스터 자격증명
  # ⚠️ 패스워드는 Secrets Manager에서 관리
  #    실제 패스워드를 이 파일에 절대 하드코딩하지 마세요!
  #
  # 패스워드 설정 방법 (배포 후):
  #   aws rds modify-db-instance \
  #     --db-instance-identifier <instance-id> \
  #     --master-user-password <new-password>
  # ---------------------------------------------------------------
  db_username   = "dbadmin"
  db_password   = "REPLACE_WITH_SECRET_PASSWORD"  # ⚠️ 반드시 배포 후 변경!

  # ---------------------------------------------------------------
  # 인스턴스 스펙
  # prod: db.t3.medium — 안정적인 워크로드 처리
  # dev:  db.t3.micro  — 비용 최소화
  #
  # 메모리 집약적 워크로드: db.r6g.large 계열 고려
  # ---------------------------------------------------------------
  db_instance_class = "db.t3.medium"

  # ---------------------------------------------------------------
  # 스토리지 설정
  # prod: 100GB 시작, 최대 500GB 자동 확장
  # 자동 확장(Autoscaling)으로 디스크 부족 장애 방지
  # ---------------------------------------------------------------
  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"

  # ---------------------------------------------------------------
  # KMS 암호화
  # prod 필수 — CMK로 스토리지 데이터 암호화
  # ---------------------------------------------------------------
  storage_encrypted       = true
  kms_key_id              = dependency.kms_rds.outputs.key_id

  # ---------------------------------------------------------------
  # Multi-AZ (고가용성)
  # prod: true  — 스탠바이 인스턴스 자동 장애 조치 (RTO < 2분)
  # dev:  false — 단일 AZ (비용 절약)
  #
  # ⚠️ Multi-AZ는 동일 리전 내 다른 AZ에 동기 복제본 유지
  #    마스터 장애 시 자동으로 스탠바이로 전환
  # ---------------------------------------------------------------
  multi_az = true

  # ---------------------------------------------------------------
  # 백업 설정
  # prod: 30일 보존 (법적/컴플라이언스 요건 충족)
  # dev:  1일 보존 (최솟값)
  # ---------------------------------------------------------------
  backup_retention_period = 30
  backup_window           = "03:00-04:00"  # UTC 새벽 3-4시 (한국 오전 12-1시)
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # ---------------------------------------------------------------
  # 삭제 방지
  # prod: deletion_protection = true + skip_final_snapshot = false
  #        → 실수 삭제 완전 방지 + 최종 스냅샷 자동 생성
  # dev:  deletion_protection = false + skip_final_snapshot = true
  # ---------------------------------------------------------------
  deletion_protection  = true
  skip_final_snapshot  = false
  final_snapshot_identifier = "terraform-practice-prod-rds-final-snapshot"

  # ---------------------------------------------------------------
  # 즉시 적용 여부
  # prod: false — 유지 보수 창(maintenance_window)에서만 변경 적용
  # dev:  true  — 즉시 적용 (빠른 개발 사이클)
  #
  # ⚠️ prod에서 apply_immediately = true 설정 시
  #    인스턴스 재시작이 필요한 변경은 즉시 다운타임 발생!
  # ---------------------------------------------------------------
  apply_immediately = false

  # ---------------------------------------------------------------
  # Performance Insights (쿼리 성능 분석)
  # prod: true — 슬로우 쿼리 식별 및 DB 성능 최적화
  # 7일 무료, 장기 보존은 추가 비용
  # ---------------------------------------------------------------
  enable_performance_insights              = true
  performance_insights_retention_period    = 7

  # ---------------------------------------------------------------
  # 향상된 모니터링
  # prod: 60초 간격 OS 레벨 메트릭 수집
  # ---------------------------------------------------------------
  monitoring_interval = 60

  # ---------------------------------------------------------------
  # 접근 제어
  # VPC CIDR 내부 접근만 허용 (ALB, 앱 서버, Bastion에서 접근)
  # ---------------------------------------------------------------
  allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
}

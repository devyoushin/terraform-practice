### =============================================================================
### prod/secrets-manager/rds/terragrunt.hcl
### PROD 환경 Secrets Manager — RDS 데이터베이스 자격증명
###
### 역할: RDS 마스터 계정 정보(username/password)를 안전하게 저장
###   - 애플리케이션에서 환경변수 대신 Secrets Manager API로 자격증명 조회
###   - RDS 엔드포인트, 포트, DB명도 함께 저장하여 연결 정보 통합 관리
###
### 의존성:
###   - kms/s3  → 시크릿 암호화 KMS 키
###   - rds     → DB 엔드포인트 / 포트 (시크릿 값에 포함)
###
### PROD 특징:
###   - recovery_window_in_days = 30 (dev: 0 — 즉시 삭제)
###     → 실수로 삭제된 시크릿 30일 이내 복구 가능
###   - KMS CMK 암호화 (dev: AWS 관리형 키)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ 시크릿 삭제 후 30일간 동일한 이름으로 재생성 불가
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

# KMS 키 의존성 (시크릿 암호화용)
dependency "kms_s3" {
  config_path = "../../kms/s3"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

# RDS 의존성 (DB 연결 정보 참조)
dependency "rds" {
  config_path = "../../rds"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    db_instance_endpoint = "terraform-practice-prod-rds.xxxxxx.ap-northeast-2.rds.amazonaws.com:5432"
    db_instance_address  = "terraform-practice-prod-rds.xxxxxx.ap-northeast-2.rds.amazonaws.com"
    db_instance_port     = 5432
    db_name              = "appdb"
    db_username          = "dbadmin"
  }
}

terraform {
  source = "../../../secrets-manager/modules/secrets-manager"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 시크릿 식별자
  # 최종 시크릿명: {project_name}/prod/rds
  # 앱에서 AWS SDK로 조회: GetSecretValue(SecretId="{project_name}/prod/rds")
  # ---------------------------------------------------------------
  secret_suffix = "rds"

  # ---------------------------------------------------------------
  # 시크릿 값 (JSON 형식)
  # 실제 패스워드는 배포 후 콘솔 또는 CLI로 직접 업데이트:
  #   aws secretsmanager update-secret \
  #     --secret-id {project_name}/prod/rds \
  #     --secret-string '{"password":"<실제_비밀번호>"}'
  #
  # ⚠️ 실제 비밀번호를 이 파일에 하드코딩하지 마세요!
  #    환경 변수 또는 배포 후 수동 업데이트 방식 사용
  # ---------------------------------------------------------------
  secret_value = {
    username = dependency.rds.outputs.db_username
    password = "REPLACE_WITH_ACTUAL_PASSWORD"  # 배포 후 수동 업데이트 필요
    host     = dependency.rds.outputs.db_instance_address
    port     = dependency.rds.outputs.db_instance_port
    dbname   = dependency.rds.outputs.db_name
    engine   = "postgres"
  }

  # ---------------------------------------------------------------
  # 시크릿 삭제 대기 기간
  # prod: 30일 — 실수 삭제 시 30일 이내 복구 가능
  # dev:  0일  — 즉시 삭제 (개발 환경 신속 정리)
  #
  # ⚠️ 삭제 후 30일 동안은 동일 이름으로 새 시크릿 생성 불가
  #    복구: aws secretsmanager restore-secret --secret-id <arn>
  # ---------------------------------------------------------------
  recovery_window_in_days = 30

  # ---------------------------------------------------------------
  # KMS 암호화
  # prod: CMK(고객 관리형 키) 사용 → 키 접근 제어 및 감사 로그 가능
  # dev:  AWS 관리형 키 사용 (비용 절약)
  # ---------------------------------------------------------------
  kms_key_arn = dependency.kms_s3.outputs.key_arn
}

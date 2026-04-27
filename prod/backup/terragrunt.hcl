### =============================================================================
### prod/backup/terragrunt.hcl
### PROD 환경 AWS Backup — 중앙 집중식 백업 관리
###
### 역할: 여러 AWS 서비스의 백업을 중앙에서 자동 관리
###   - 백업 대상: RDS, DynamoDB, EBS, EFS, EC2 등
###   - 백업 볼트(Vault): KMS 암호화된 안전한 백업 저장소
###   - 백업 계획(Plan): 일정 및 보존 규칙 자동 적용
###
### PROD 특징:
###   - backup_retention_days = 90   (3개월 보존 — 법적 요건 고려)
###   - cold_storage_after_days = 30 (30일 후 Glacier로 이동 → 비용 절약)
###   - KMS CMK 암호화 (백업 볼트 보호)
###
### 의존성:
###   - kms/s3 → 백업 볼트 암호화 KMS 키
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ 백업 보존 기간은 법적/컴플라이언스 요건에 맞게 설정
### ⚠️ cold_storage_after_days는 backup_retention_days보다 짧아야 함
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "kms_s3" {
  config_path = "../kms/s3"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_id  = "00000000-0000-0000-0000-000000000000"
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

terraform {
  source = "../../backup/modules/backup"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 백업 볼트 암호화
  # prod: CMK로 백업 데이터 암호화 (백업 볼트 잠금과 함께 사용)
  # ---------------------------------------------------------------
  kms_key_arn = dependency.kms_s3.outputs.key_arn

  # ---------------------------------------------------------------
  # 백업 보존 기간
  # prod: 90일 — 3개월 보존 (일반적인 컴플라이언스 요건)
  # dev:  7일  — 비용 최소화
  #
  # 법적 요건에 따른 조정:
  #   - 일반: 30~90일
  #   - 금융/의료: 7년 이상
  #   - GDPR 적용: 데이터 성격에 따라 다름
  # ---------------------------------------------------------------
  backup_retention_days = 90

  # ---------------------------------------------------------------
  # 콜드 스토리지 이동 (Glacier)
  # prod: 30일 후 Glacier로 이동 → 스토리지 비용 최적화
  # Glacier 비용: $0.004/GB (Standard EBS 대비 약 80% 절감)
  #
  # ⚠️ cold_storage_after_days < backup_retention_days 조건 충족 필요
  # ⚠️ Glacier에서 복구 시간: Standard 3~5시간, Expedited 1~5분(비용↑)
  # ---------------------------------------------------------------
  cold_storage_after_days = 30

  # ---------------------------------------------------------------
  # 백업 일정 (Cron 표현식, UTC 기준)
  # 매일 새벽 4시(UTC) = 한국 오후 1시
  # ---------------------------------------------------------------
  backup_schedule = "cron(0 4 * * ? *)"

  # ---------------------------------------------------------------
  # 백업 대상 리소스 태그
  # "Backup=true" 태그가 붙은 모든 리소스 자동 백업
  # 각 리소스에 태그를 추가하여 백업 대상 관리
  # ---------------------------------------------------------------
  backup_tag_key   = "Backup"
  backup_tag_value = "true"

  # ---------------------------------------------------------------
  # 백업 볼트 잠금 (Vault Lock)
  # prod: GOVERNANCE 모드 — 잠금 기간 내 삭제 차단
  # 랜섬웨어 공격으로부터 백업 보호
  # ---------------------------------------------------------------
  enable_vault_lock    = true
  vault_lock_min_days  = 7
  vault_lock_max_days  = 90
}

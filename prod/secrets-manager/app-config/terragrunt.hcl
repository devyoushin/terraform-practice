### =============================================================================
### prod/secrets-manager/app-config/terragrunt.hcl
### PROD 환경 Secrets Manager — 애플리케이션 설정 시크릿
###
### 역할: 애플리케이션 레벨의 민감한 설정값 저장
###   - 외부 API 키 (결제 게이트웨이, 이메일 서비스 등)
###   - JWT 시크릿 키
###   - 서드파티 OAuth 클라이언트 정보
###   - 기타 애플리케이션 민감 설정
###
### 의존성:
###   - kms/s3 → 시크릿 암호화 KMS 키
###
### PROD 특징:
###   - recovery_window_in_days = 30 (dev: 0)
###   - KMS CMK 암호화
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ 실제 API 키 등 민감 값은 배포 후 콘솔/CLI로 업데이트할 것
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

terraform {
  source = "../../../secrets-manager/modules/secrets-manager"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 시크릿 식별자
  # 최종 시크릿명: {project_name}/prod/app-config
  # 앱에서 AWS SDK로 조회:
  #   GetSecretValue(SecretId="{project_name}/prod/app-config")
  # ---------------------------------------------------------------
  secret_suffix = "app-config"

  # ---------------------------------------------------------------
  # 시크릿 초기값 (플레이스홀더)
  # ⚠️ 아래 값들은 실제 값으로 교체 필요!
  #
  # 배포 후 실제 값 업데이트 방법:
  #   aws secretsmanager update-secret \
  #     --secret-id {project_name}/prod/app-config \
  #     --secret-string '{
  #       "jwt_secret": "<실제_JWT_시크릿>",
  #       "payment_api_key": "<결제_API_키>",
  #       "smtp_password": "<SMTP_패스워드>"
  #     }'
  #
  # 또는 환경 변수로 주입:
  #   export TF_VAR_jwt_secret="<실제값>"
  # ---------------------------------------------------------------
  secret_value = {
    jwt_secret       = "REPLACE_WITH_JWT_SECRET"
    payment_api_key  = "REPLACE_WITH_PAYMENT_API_KEY"
    smtp_password    = "REPLACE_WITH_SMTP_PASSWORD"
    oauth_client_id  = "REPLACE_WITH_OAUTH_CLIENT_ID"
    oauth_client_secret = "REPLACE_WITH_OAUTH_CLIENT_SECRET"
  }

  # ---------------------------------------------------------------
  # 시크릿 삭제 대기 기간
  # prod: 30일 — 실수 삭제 시 복구 기간 확보
  # dev:  0일  — 즉시 삭제
  # ---------------------------------------------------------------
  recovery_window_in_days = 30

  # ---------------------------------------------------------------
  # KMS 암호화
  # prod: CMK 사용 (키 접근 제어 및 CloudTrail 감사 로그)
  # ---------------------------------------------------------------
  kms_key_arn = dependency.kms_s3.outputs.key_arn
}

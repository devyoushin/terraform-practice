### =============================================================================
### dev/secrets-manager/app-config/terragrunt.hcl
### DEV 환경 Secrets Manager — 애플리케이션 설정 시크릿
###
### 역할: API 키, 외부 서비스 토큰, 앱 설정값 등을 안전하게 저장
###       RDS 자격증명과 분리하여 접근 권한을 세분화
### DEV 특징:
###   - recovery_window_in_days = 0: 즉시 삭제
###   - 단순 키-값 구조로 다양한 설정값 저장
###   - KMS 암호화: AWS 관리형 키 사용
### 의존성: 없음
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../secrets-manager/modules/secrets-manager"
}

inputs = {
  # ---------------------------------------------------------------
  # 시크릿 이름
  # ---------------------------------------------------------------
  secret_name        = "terraform-practice-dev-app-config"
  secret_description = "DEV 환경 애플리케이션 설정값 (API 키, 외부 서비스 토큰 등)"

  # ---------------------------------------------------------------
  # 초기 시크릿 값
  # 배포 후 실제 값으로 업데이트 필요
  # CLI: aws secretsmanager put-secret-value \
  #        --secret-id terraform-practice-dev-app-config \
  #        --secret-string '{"api_key":"real-key","jwt_secret":"real-secret"}'
  # ---------------------------------------------------------------
  secret_string = jsonencode({
    # 애플리케이션 JWT 서명 키
    # 실제 값은 배포 후 콘솔 또는 CLI로 교체할 것
    jwt_secret = "CHANGE_ME_USE_ENV_VAR"
    # 외부 결제 API 키 (예시)
    payment_api_key = "CHANGE_ME_USE_ENV_VAR"
    # 이메일 서비스 API 키 (예시)
    email_api_key = "CHANGE_ME_USE_ENV_VAR"
    # 앱 실행 환경
    app_env = "development"
  })

  # ---------------------------------------------------------------
  # 삭제 복구 대기 기간
  # dev: 0 = 즉시 삭제
  # prod: 30일 (중요 설정값 실수 삭제 복구)
  # ---------------------------------------------------------------
  recovery_window_in_days = 0

  # ---------------------------------------------------------------
  # KMS 암호화
  # dev: AWS 관리형 키 사용
  # prod: CMK 사용으로 키 접근 감사 가능
  # ---------------------------------------------------------------
  kms_key_id = null
}

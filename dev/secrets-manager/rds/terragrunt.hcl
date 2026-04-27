### =============================================================================
### dev/secrets-manager/rds/terragrunt.hcl
### DEV 환경 Secrets Manager — RDS 자격증명 시크릿
###
### 역할: RDS 데이터베이스의 username/password를 안전하게 저장
###       애플리케이션은 이 시크릿을 참조하여 DB에 접속
### DEV 특징:
###   - recovery_window_in_days = 0: 즉시 삭제 (dev 환경 초기화 편의)
###     prod: 30일 (실수 삭제 복구 기간)
###   - KMS 암호화: AWS 관리형 키 사용 (dev는 CMK 불필요)
###     prod: KMS CMK 필수
### 의존성: 없음 (rds 모듈보다 먼저 생성하여 password를 RDS에 주입 가능)
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
  # Secrets Manager 콘솔에서 이 이름으로 식별됨
  # 애플리케이션 코드에서: secretsmanager:GetSecretValue 호출 시 사용
  # ---------------------------------------------------------------
  secret_name        = "terraform-practice-dev-rds"
  secret_description = "DEV 환경 RDS MySQL 자격증명 (username/password)"

  # ---------------------------------------------------------------
  # 초기 시크릿 값 (JSON 형식)
  # 주의: 실제 비밀번호는 아래처럼 환경변수나 별도 방법으로 주입할 것
  # 배포 후 AWS 콘솔 또는 CLI로 값을 업데이트하여 사용
  # ---------------------------------------------------------------
  secret_string = jsonencode({
    username = "devadmin"
    # 실제 비밀번호는 배포 후 AWS 콘솔에서 직접 수정할 것
    # CLI: aws secretsmanager put-secret-value --secret-id terraform-practice-dev-rds --secret-string '{"username":"devadmin","password":"YOUR_PASSWORD"}'
    password = "CHANGE_ME_USE_ENV_VAR"
    engine   = "mysql"
    port     = 3306
    dbname   = "devdb"
  })

  # ---------------------------------------------------------------
  # 삭제 복구 대기 기간
  # dev: 0 = 즉시 삭제 (terraform destroy 시 빠른 정리)
  # prod: 30일 (실수로 삭제된 시크릿 복구 기간)
  # ---------------------------------------------------------------
  recovery_window_in_days = 0

  # ---------------------------------------------------------------
  # KMS 암호화
  # dev: null = AWS 관리형 키 사용 (추가 비용 없음)
  # prod: KMS CMK ARN 지정 (kms/rds 모듈 출력값 사용)
  # ---------------------------------------------------------------
  kms_key_id = null
}

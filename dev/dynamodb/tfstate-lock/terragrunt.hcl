### =============================================================================
### dev/dynamodb/tfstate-lock/terragrunt.hcl
### DEV 환경 DynamoDB — Terraform 상태 잠금 테이블 (tfstate-lock)
###
### 역할: Terraform 원격 상태 파일의 동시 쓰기를 방지하는 잠금 테이블
###       여러 개발자가 동시에 terraform apply 실행 시 충돌 방지
### 중요: 이 테이블은 bootstrap/ 에서 이미 생성되어 있을 수 있음
###       bootstrap/main.tf 에서 생성된 테이블과 이름이 다른지 확인 필요
###       (bootstrap: terraform-practice-tfstate-lock,
###        이 모듈: terraform-practice-dev-tfstate-lock — 환경별 분리)
### DEV 특징:
###   - billing_mode = "PAY_PER_REQUEST": 잠금 요청은 간헐적 → 요청당 과금 유리
###   - enable_pitr = false: 잠금 테이블은 복구 불필요
###   - deletion_protection = false
### 의존성: 없음
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../dynamodb/modules/dynamodb"
}

inputs = {
  # ---------------------------------------------------------------
  # 테이블 이름
  # Terraform backend 설정의 dynamodb_table 값과 일치해야 함
  # 루트 terragrunt.hcl: dynamodb_table = "terraform-practice-tfstate-lock"
  # 이 테이블은 dev 환경 전용 추가 잠금 테이블
  # ---------------------------------------------------------------
  table_name = "terraform-practice-dev-tfstate-lock"

  # ---------------------------------------------------------------
  # 기본 키
  # Terraform이 요구하는 필수 구조:
  #   hash_key = "LockID" (반드시 이 이름이어야 함)
  # ---------------------------------------------------------------
  hash_key      = "LockID"
  hash_key_type = "S"

  # ---------------------------------------------------------------
  # 빌링 모드
  # 상태 잠금은 apply 시에만 발생 → PAY_PER_REQUEST 적합
  # ---------------------------------------------------------------
  billing_mode = "PAY_PER_REQUEST"

  # ---------------------------------------------------------------
  # TTL 비활성화
  # 잠금 항목은 Terraform이 직접 관리 (자동 만료 불필요)
  # ---------------------------------------------------------------
  enable_ttl = false

  # ---------------------------------------------------------------
  # PITR 비활성화
  # 잠금 테이블 데이터는 복구 불필요
  # ---------------------------------------------------------------
  enable_pitr = false

  # ---------------------------------------------------------------
  # 삭제 보호
  # dev: false
  # prod: true (상태 잠금 테이블 삭제 시 동시 실행 보호 불가)
  # ---------------------------------------------------------------
  deletion_protection = false

  # ---------------------------------------------------------------
  # DynamoDB Streams 비활성화
  # ---------------------------------------------------------------
  enable_streams = false
}

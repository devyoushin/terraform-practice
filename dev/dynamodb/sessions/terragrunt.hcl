### =============================================================================
### dev/dynamodb/sessions/terragrunt.hcl
### DEV 환경 DynamoDB — 세션 테이블 (sessions)
###
### 역할: 사용자 세션 데이터를 저장하는 DynamoDB 테이블
###       Redis 대신 서버리스 세션 스토어로 활용 가능
### DEV 특징:
###   - billing_mode = "PAY_PER_REQUEST": 사용량 기반 요금 (dev 초기 트래픽 적음)
###   - enable_pitr = false: Point-in-Time Recovery 비활성화 (비용 절약)
###   - deletion_protection = false: 자유로운 삭제
###   - DynamoDB Streams 비활성화 (prod에서 Lambda 트리거용으로 활용)
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
  # 전체 이름: terraform-practice-dev-sessions
  # ---------------------------------------------------------------
  table_name = "terraform-practice-dev-sessions"

  # ---------------------------------------------------------------
  # 기본 키 설계
  # hash_key: 파티션 키 (세션 ID로 직접 조회)
  # range_key: 필요 시 정렬 키 추가 가능
  # ---------------------------------------------------------------
  hash_key      = "session_id"
  hash_key_type = "S" # S=String, N=Number, B=Binary

  # ---------------------------------------------------------------
  # 빌링 모드
  # PAY_PER_REQUEST: 요청당 과금 (dev: 트래픽 예측 어려울 때 유리)
  # PROVISIONED: 사전 프로비저닝 (prod: 안정적 트래픽에서 비용 효율)
  # ---------------------------------------------------------------
  billing_mode = "PAY_PER_REQUEST"

  # ---------------------------------------------------------------
  # TTL (Time To Live) — 세션 자동 만료
  # 세션 테이블에 TTL 활성화하여 만료된 세션 자동 정리
  # ---------------------------------------------------------------
  enable_ttl    = true
  ttl_attribute = "expires_at"

  # ---------------------------------------------------------------
  # Point-in-Time Recovery (PITR)
  # dev: false (비용 절약, 세션 데이터는 복구 불필요)
  # prod: true (35일 이내 특정 시점으로 복구 가능)
  # ---------------------------------------------------------------
  enable_pitr = false

  # ---------------------------------------------------------------
  # 삭제 보호
  # dev: false (terraform destroy 시 즉시 삭제)
  # prod: true (실수로 인한 테이블 삭제 방지)
  # ---------------------------------------------------------------
  deletion_protection = false

  # ---------------------------------------------------------------
  # DynamoDB Streams
  # dev: false (Lambda 트리거 불필요)
  # prod: true (세션 변경 이벤트를 Lambda로 처리하는 경우)
  # ---------------------------------------------------------------
  enable_streams = false
}

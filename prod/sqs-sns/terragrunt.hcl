### =============================================================================
### prod/sqs-sns/terragrunt.hcl
### PROD 환경 SQS/SNS — 메시지 큐 및 알림
###
### 역할: 비동기 메시지 처리 및 이벤트 기반 아키텍처
###   - SQS: 작업 큐 (이미지 처리, 이메일 발송 등)
###   - SQS DLQ: 처리 실패 메시지 보관
###   - SNS: 이벤트 발행 및 구독자 알림
###   - KMS 암호화: 메시지 민감 정보 보호
###
### PROD 특징:
###   - visibility_timeout_seconds = 300  (5분 — 처리 시간 확보)
###   - message_retention_seconds = 1209600 (14일 최대 보존)
###   - max_receive_count = 5             (5회 실패 시 DLQ로 이동)
###   - enable_kms = true                 (메시지 암호화)
###   - enable_alarms = true              (큐 깊이/실패 알람)
###
### 의존성:
###   - kms/s3    → SQS/SNS 암호화 KMS 키
###   - cloudwatch → 알람 SNS 토픽 (알람 발송용)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
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

dependency "cloudwatch" {
  config_path = "../cloudwatch"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    alarm_topic_arn = "arn:aws:sns:ap-northeast-2:123456789012:terraform-practice-prod-alarms"
  }
}

terraform {
  source = "../../sqs-sns/modules/sqs-sns"
}

inputs = {
  # ---------------------------------------------------------------
  # 가시성 제한 시간 (Visibility Timeout)
  # 메시지를 수신한 소비자가 처리를 완료해야 하는 시간
  # prod: 300초(5분) — 무거운 작업(이미지 변환 등)에 충분한 시간
  # dev:  30초       — 빠른 테스트 사이클
  #
  # ⚠️ Lambda 타임아웃의 6배 이상으로 설정 권장
  # ---------------------------------------------------------------
  visibility_timeout_seconds = 300

  # ---------------------------------------------------------------
  # 메시지 보존 기간
  # prod: 1209600초(14일) — SQS 최대값, 처리 지연 시 메시지 손실 방지
  # dev:  86400초(1일)    — 비용 절약
  # ---------------------------------------------------------------
  message_retention_seconds = 1209600

  # ---------------------------------------------------------------
  # Dead Letter Queue (DLQ) 설정
  # max_receive_count: 메시지를 DLQ로 이동하기 전 최대 수신 시도 횟수
  # prod: 5회 — 일시적 오류 재시도 후 지속 실패 시 DLQ 격리
  # dev:  3회
  #
  # DLQ 메시지 처리 방법:
  #   1. DLQ 모니터링 알람 설정 (enable_alarms로 자동 설정)
  #   2. DLQ 메시지 분석 → 오류 원인 파악
  #   3. 수정 후 DLQ → 원본 큐로 메시지 재이동
  # ---------------------------------------------------------------
  max_receive_count = 5

  # ---------------------------------------------------------------
  # KMS 암호화
  # prod: true — SQS 메시지 암호화 (민감 데이터 보호)
  # dev:  false — 비용 절약 (KMS API 호출 비용)
  # ---------------------------------------------------------------
  enable_kms  = true
  kms_key_arn = dependency.kms_s3.outputs.key_arn

  # ---------------------------------------------------------------
  # CloudWatch 알람
  # prod: 활성화 — 큐 이상 상황 즉시 알람
  # 모니터링 항목:
  #   - ApproximateNumberOfMessagesNotVisible: 처리 중 메시지 수 급증
  #   - ApproximateAgeOfOldestMessage: 가장 오래된 메시지 대기 시간
  #   - NumberOfMessagesSent to DLQ: DLQ 메시지 급증
  # ---------------------------------------------------------------
  enable_alarms   = true
  alarm_topic_arn = dependency.cloudwatch.outputs.alarm_topic_arn

  # ---------------------------------------------------------------
  # 큐 지연 (Delay Seconds) — 선택적
  # 메시지 발행 후 소비자가 수신 가능한 시점까지 지연
  # ---------------------------------------------------------------
  delay_seconds = 0

  # ---------------------------------------------------------------
  # 최대 메시지 크기
  # 기본값 256KB, SQS 최대 256KB
  # 큰 페이로드는 S3에 저장 후 SQS에 S3 경로만 전송 권장
  # ---------------------------------------------------------------
  max_message_size = 262144  # 256KB
}

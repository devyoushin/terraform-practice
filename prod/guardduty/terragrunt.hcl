### =============================================================================
### prod/guardduty/terragrunt.hcl
### PROD 환경 GuardDuty — 위협 탐지 서비스
###
### 역할: AWS 계정 내 악의적 활동 및 비정상 동작 자동 탐지
###   - VPC Flow Logs, CloudTrail, DNS 쿼리 분석
###   - S3 버킷 이상 접근 탐지
###   - EC2/EKS 악성코드 탐지
###   - 탐지 결과를 CloudWatch 알람으로 즉시 알림
###
### PROD 특징:
###   - finding_frequency = "FIFTEEN_MINUTES"  (15분 — 빠른 탐지)
###   - enable_s3_logs = true                   (S3 데이터 이벤트 분석)
###   - enable_malware_protection = true        (EC2 악성코드 스캔)
###   - finding_min_severity = "MEDIUM"         (중간 이상 결과만 알림)
###
### 의존성:
###   - cloudwatch → 알람 SNS 토픽 (탐지 결과 알림)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ GuardDuty 활성화 비용: 분석 이벤트 수에 따라 변동
###    (VPC Flow Logs GB당 $1.00, CloudTrail 이벤트 100만건당 $4.00)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "cloudwatch" {
  config_path = "../cloudwatch"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    alarm_topic_arn = "arn:aws:sns:ap-northeast-2:123456789012:terraform-practice-prod-alarms"
  }
}

terraform {
  source = "../../guardduty/modules/guardduty"
}

inputs = {
  # ---------------------------------------------------------------
  # 탐지 결과 업데이트 빈도
  # prod: FIFTEEN_MINUTES — 15분마다 탐지 결과 업데이트
  # dev:  SIX_HOURS        — 6시간 (비용 절약)
  #
  # 옵션: FIFTEEN_MINUTES | ONE_HOUR | SIX_HOURS
  # 빈도가 높을수록 비용 증가 (FIFTEEN_MINUTES가 가장 비쌈)
  # ---------------------------------------------------------------
  finding_frequency = "FIFTEEN_MINUTES"

  # ---------------------------------------------------------------
  # S3 보호 (S3 Protection)
  # prod: true — S3 버킷의 비정상 접근 패턴 탐지
  #   - 비정상적으로 많은 오브젝트 다운로드
  #   - 알 수 없는 IP에서 민감 데이터 접근
  #   - 퍼블릭 접근으로 변경되는 버킷
  # ---------------------------------------------------------------
  enable_s3_logs = true

  # ---------------------------------------------------------------
  # 악성코드 보호 (Malware Protection)
  # prod: true — EC2 인스턴스 및 컨테이너 악성코드 자동 스캔
  #   탐지 시: 해당 인스턴스 격리 → 포렌식 조사 → 복구
  # ---------------------------------------------------------------
  enable_malware_protection = true

  # ---------------------------------------------------------------
  # 최소 탐지 심각도
  # prod: MEDIUM — 중간(Medium) 이상의 탐지 결과만 알림 발송
  # dev:  HIGH   — 높은 위협만 알림 (노이즈 감소)
  #
  # 심각도 단계:
  #   LOW (1~3.9): 정보성 — 알림 불필요
  #   MEDIUM (4~6.9): 주의 필요 — 업무 시간 내 검토
  #   HIGH (7~8.9): 즉시 대응 — 24/7 알림
  #   CRITICAL (9~10): 긴급 대응 — 즉각 에스컬레이션
  # ---------------------------------------------------------------
  finding_min_severity = "MEDIUM"

  # ---------------------------------------------------------------
  # 알림 SNS 토픽
  # MEDIUM 이상 탐지 결과 → SNS → 이메일/PagerDuty 알림
  # ---------------------------------------------------------------
  alarm_topic_arn = dependency.cloudwatch.outputs.alarm_topic_arn

  # ---------------------------------------------------------------
  # EKS 보호 (Runtime Monitoring) — 선택적
  # EKS 클러스터에서 실행 중인 컨테이너의 런타임 동작 탐지
  # ---------------------------------------------------------------
  enable_eks_protection = true

  # ---------------------------------------------------------------
  # RDS 보호 — 선택적
  # RDS 로그인 이상 동작 탐지 (브루트포스, 자격증명 유출 등)
  # ---------------------------------------------------------------
  enable_rds_protection = true
}

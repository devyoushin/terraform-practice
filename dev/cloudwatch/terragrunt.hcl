### =============================================================================
### dev/cloudwatch/terragrunt.hcl
### DEV 환경 CloudWatch (모니터링 및 로깅)
###
### 역할: 애플리케이션 로그 수집, 메트릭 알람, 대시보드 구성
###       모든 모듈의 로그 그룹을 중앙에서 관리
### DEV 특징:
###   - log_retention_days = 7: 로그 보존 7일 (비용 최소화)
###     prod: 90일 이상 (감사 및 장애 분석)
###   - enable_alarm_notification = false: SNS 알람 발송 비활성화
###     prod: true (PagerDuty/Slack 연동)
###   - enable_dashboard = false: 대시보드 생성 비활성화 (비용 절약)
###     prod: true (실시간 서비스 현황 모니터링)
### 의존성: 없음
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../cloudwatch/modules/cloudwatch"
}

inputs = {
  # ---------------------------------------------------------------
  # 로그 보존 기간
  # dev: 7일 (CloudWatch Logs 비용 절약)
  # prod: 90일 (보안 감사, 장애 원인 분석)
  # 지원 값: 1,3,5,7,14,30,60,90,120,150,180,365,400,545,731,1827,3653
  # ---------------------------------------------------------------
  log_retention_days = 7

  # ---------------------------------------------------------------
  # 관리할 로그 그룹 목록
  # 각 서비스별 로그 그룹을 이 모듈에서 중앙 관리
  # ---------------------------------------------------------------
  log_group_names = [
    "/aws/eks/dev-eks/cluster",
    "/aws/rds/instance/terraform-practice-dev-rds/error",
    "/aws/rds/instance/terraform-practice-dev-rds/general",
    "/aws/elasticache/cluster/terraform-practice-dev-redis/redis",
    "/application/terraform-practice/dev",
  ]

  # ---------------------------------------------------------------
  # SNS 알람 알림
  # dev: false (야간 알람으로 인한 불필요한 알림 방지)
  # prod: true (이메일/Slack/PagerDuty 연동)
  # ---------------------------------------------------------------
  enable_alarm_notification = false

  # ---------------------------------------------------------------
  # CloudWatch 대시보드
  # dev: false (비용 절약 — 대시보드 $3/월)
  # prod: true (운영팀 실시간 모니터링)
  # ---------------------------------------------------------------
  enable_dashboard = false

  # ---------------------------------------------------------------
  # 알람 임계값 설정 (dev 환경 기준)
  # dev에서도 기본 알람을 정의해두면 prod 전환 시 참고 가능
  # ---------------------------------------------------------------
  cpu_alarm_threshold    = 90 # CPU 90% 초과 시 알람 (dev: 느슨하게)
  memory_alarm_threshold = 90 # 메모리 90% 초과 시 알람
}

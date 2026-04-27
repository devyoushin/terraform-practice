### =============================================================================
### dev/waf/terragrunt.hcl
### DEV 환경 WAF (Web Application Firewall)
###
### 역할: ALB 앞에 위치하여 SQL Injection, XSS 등 웹 공격 방어
###       AWS Managed Rules 사용으로 빠른 보호 적용
### DEV 특징:
###   - scope = "REGIONAL": ALB에 연결 (CLOUDFRONT는 us-east-1에서만 생성)
###   - managed_rules_action = "count": 차단 대신 카운팅만 (모니터링 모드)
###     prod: "block" — 실제 공격 차단
###   - enable_rate_limiting = false: 속도 제한 없음 (개발 테스트 편의)
###     prod: true — DDoS/브루트포스 방지
### 의존성: 없음 (ALB에 WAF를 연결할 때는 alb 의존성 추가 가능)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../waf/modules/waf"
}

inputs = {
  # ---------------------------------------------------------------
  # WAF 범위
  # REGIONAL: ALB, API Gateway, AppSync 에 연결
  # CLOUDFRONT: CloudFront 배포에 연결 (반드시 us-east-1에서 생성)
  # ---------------------------------------------------------------
  scope = "REGIONAL"

  # ---------------------------------------------------------------
  # AWS Managed Rules 동작 모드
  # count: 규칙에 매칭된 요청을 카운팅만 (트래픽 차단 없음)
  #        → dev에서 오탐(False Positive) 확인 후 prod에서 block 전환
  # block: 규칙에 매칭된 요청을 실제 차단
  # ---------------------------------------------------------------
  managed_rules_action = "count"

  # ---------------------------------------------------------------
  # 적용할 AWS Managed Rule Groups
  # AWSManagedRulesCommonRuleSet: OWASP Top 10 기본 보호
  # AWSManagedRulesSQLiRuleSet: SQL Injection 방어
  # AWSManagedRulesKnownBadInputsRuleSet: 알려진 악성 입력 차단
  # ---------------------------------------------------------------
  managed_rule_groups = [
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesSQLiRuleSet",
    "AWSManagedRulesKnownBadInputsRuleSet",
  ]

  # ---------------------------------------------------------------
  # 속도 제한 (Rate Limiting)
  # dev: false (개발 테스트 시 속도 제한으로 인한 차단 방지)
  # prod: true (IP당 5분에 2000 요청 등 임계값 설정)
  # ---------------------------------------------------------------
  enable_rate_limiting = false

  # ---------------------------------------------------------------
  # WAF 로그 (CloudWatch Logs / S3 / Kinesis)
  # dev: 비활성화 (비용 절약)
  # prod: 활성화 (공격 패턴 분석 및 보안 감사)
  # ---------------------------------------------------------------
  enable_logging = false
}

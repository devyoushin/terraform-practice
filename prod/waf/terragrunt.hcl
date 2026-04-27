### =============================================================================
### prod/waf/terragrunt.hcl
### PROD 환경 WAF — Web Application Firewall
###
### 역할: ALB 또는 CloudFront 앞단의 웹 방화벽
###   - AWS 관리형 규칙(AWSManagedRules) 적용
###   - 속도 제한(Rate Limiting)으로 DDoS/브루트포스 방지
###   - SQL Injection, XSS, OWASP Top 10 방어
###
### PROD 특징:
###   - managed_rules_action = "none"  (BLOCK 모드 — dev는 COUNT)
###   - enable_rate_limiting = true    (속도 제한 활성화)
###   - rate_limit = 2000              (IP당 5분 2000 요청)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ WAF 비용: WebACL당 $5/월 + 규칙당 $1/월 + 요청당 $0.60/백만
### ⚠️ 처음 prod 배포 시 COUNT 모드로 시작 후 로그 분석 후 BLOCK 전환 권장
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../waf/modules/waf"
}

inputs = {
  # ---------------------------------------------------------------
  # WAF 범위 (Scope)
  # REGIONAL: ALB, API Gateway, AppSync — 리전별 적용
  # CLOUDFRONT: CloudFront 배포에 적용 (us-east-1에 생성해야 함)
  # ---------------------------------------------------------------
  scope = "REGIONAL"

  # ---------------------------------------------------------------
  # 관리형 규칙 동작 모드
  # prod: "none"  — BLOCK 모드 (실제 차단 활성화)
  # dev:  "count" — COUNT 모드 (차단 없이 감지만)
  #
  # AWS 관리형 규칙 포함:
  #   - AWSManagedRulesCommonRuleSet    (OWASP Top 10)
  #   - AWSManagedRulesKnownBadInputsRuleSet (Log4j, SQLi 등)
  #   - AWSManagedRulesSQLiRuleSet      (SQL Injection)
  #
  # ⚠️ 초기 배포 시 "count" 로 시작하여 정탐/오탐 분석 후 "none"으로 전환
  # ---------------------------------------------------------------
  managed_rules_action = "none"

  # ---------------------------------------------------------------
  # 속도 제한 (Rate Limiting)
  # prod: 활성화 — IP당 5분 내 2000 요청 초과 시 차단
  # dev:  비활성화 또는 높은 임계값
  #
  # 적절한 임계값 설정:
  #   - 일반 사용자 패턴 분석 후 조정
  #   - API 엔드포인트는 더 낮은 임계값 (예: 100/분)
  #   - 정적 콘텐츠는 더 높은 임계값 가능
  # ---------------------------------------------------------------
  enable_rate_limiting = true
  rate_limit           = 2000

  # ---------------------------------------------------------------
  # CloudWatch 메트릭
  # WAF 차단 이벤트를 CloudWatch에서 모니터링
  # ---------------------------------------------------------------
  enable_cloudwatch_metrics = true

  # ---------------------------------------------------------------
  # WAF 로그
  # 차단/허용 요청 로그를 CloudWatch Logs 또는 S3에 저장
  # ---------------------------------------------------------------
  enable_logging = true

  # ---------------------------------------------------------------
  # IP 허용 목록 (Whitelist) — 선택적
  # 오피스 IP 또는 CI/CD 서버 IP를 허용 목록에 추가
  # ---------------------------------------------------------------
  # ip_whitelist = [
  #   "REPLACE_WITH_OFFICE_IP/32",
  #   "REPLACE_WITH_VPN_CIDR/24",
  # ]
}

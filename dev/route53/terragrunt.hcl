### =============================================================================
### dev/route53/terragrunt.hcl
### DEV 환경 Route53 (DNS 관리)
###
### 역할: dev 환경 도메인의 DNS 레코드 관리
###       ALB DNS 이름을 커스텀 도메인에 매핑 (Alias 레코드)
### DEV 특징:
###   - create_zone = true: dev 전용 Hosted Zone 생성
###   - domain_name = "dev.example.com": 실제 도메인으로 교체 필요
###   - enable_health_checks = false: 헬스 체크 비활성화 (비용 절약)
###   - enable_failover = false: 장애조치 라우팅 비활성화
### 주의: Route53 헬스 체크 CloudWatch 알람은 반드시 us-east-1 리전에서 생성
### 의존성: alb (ALB의 DNS 이름과 Zone ID를 Route53 Alias 레코드에 사용)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "alb" {
  config_path = "../alb"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    alb_id          = "arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/terraform-practice-dev-alb/0000000000000000"
    alb_arn         = "arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/terraform-practice-dev-alb/0000000000000000"
    alb_dns_name    = "terraform-practice-dev-alb-123456789.ap-northeast-2.elb.amazonaws.com"
    alb_zone_id     = "ZWKZPGTI48KDX"
    target_group_arn = "arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:targetgroup/terraform-practice-dev-tg/0000000000000000"
    security_group_id = "sg-00000000000000000"
  }
}

terraform {
  source = "../../route53/modules/route53"
}

inputs = {
  # ---------------------------------------------------------------
  # Hosted Zone 설정
  # create_zone = true: 새 Hosted Zone 생성
  # create_zone = false: 기존 Hosted Zone에 레코드만 추가
  # ---------------------------------------------------------------
  create_zone = true

  # ---------------------------------------------------------------
  # 도메인 이름
  # 실제 소유한 도메인으로 교체 필요
  # dev 환경은 서브도메인으로 분리 (dev.example.com)
  # prod 환경: example.com
  # ---------------------------------------------------------------
  domain_name = "dev.example.com"

  # ---------------------------------------------------------------
  # ALB Alias 레코드
  # A 레코드 대신 Alias 레코드 사용 (AWS 권장)
  # ALB IP가 변경되어도 DNS 자동 반영
  # ---------------------------------------------------------------
  alb_dns_name = dependency.alb.outputs.alb_dns_name
  alb_zone_id  = dependency.alb.outputs.alb_zone_id

  # ---------------------------------------------------------------
  # 헬스 체크
  # dev: false (비용 절약 — 헬스 체크당 $0.5~1.0/월)
  # prod: true (장애 시 DNS 자동 전환을 위한 헬스 체크)
  # 주의: Route53 헬스 체크 알람은 us-east-1에서 생성해야 함
  # ---------------------------------------------------------------
  enable_health_checks = false

  # ---------------------------------------------------------------
  # 장애조치 라우팅 (Failover Routing)
  # dev: false (단일 ALB로 충분)
  # prod: true (기본 + 대기 엔드포인트 구성으로 고가용성)
  # ---------------------------------------------------------------
  enable_failover = false

  # ---------------------------------------------------------------
  # DNS 레코드 TTL
  # dev: 300초 (5분) — 빠른 DNS 변경 반영
  # prod: 300초 (Alias 레코드는 TTL 설정이 AWS에서 자동 관리)
  # ---------------------------------------------------------------
  record_ttl = 300
}

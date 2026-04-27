### =============================================================================
### prod/route53/terragrunt.hcl
### PROD 환경 Route53 — DNS 관리
###
### 역할: 도메인 DNS 레코드 관리 및 헬스 체크
###   - ALB를 가리키는 A 레코드(Alias) 생성
###   - 헬스 체크 기반 DNS 장애 조치(Failover) 구성
###   - CloudWatch 알람과 연동한 헬스 체크 상태 모니터링
###
### PROD 특징:
###   - create_zone = true         (Hosted Zone 생성)
###   - enable_health_checks = true (Route53 헬스 체크 활성화)
###   - enable_failover = true      (장애 조치 라우팅 정책)
###
### 참고: Route53 헬스 체크 CloudWatch 알람은 반드시 us-east-1 리전!
###
### 의존성:
###   - alb        → ALB DNS 이름 / Zone ID (A 레코드 Alias 대상)
###   - cloudwatch → 알람 SNS 토픽 ARN (헬스 체크 알람 연동)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ 도메인 등록기(Registrar)에서 NS 레코드를 Route53 NS 서버로 교체 필요
### ⚠️ 도메인명을 실제 도메인으로 교체 (example.com → 실제 도메인)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    alb_id          = "terraform-practice-prod-alb"
    alb_arn         = "arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/terraform-practice-prod-alb/0000000000000000"
    alb_dns_name    = "terraform-practice-prod-alb-0000000000.ap-northeast-2.elb.amazonaws.com"
    alb_zone_id     = "ZWKZPGTI48KDX"
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
  source = "../../route53/modules/route53"
}

inputs = {
  # ---------------------------------------------------------------
  # Hosted Zone 생성
  # prod: true — 프로덕션 도메인의 Route53 Hosted Zone 생성
  #
  # ⚠️ Hosted Zone 생성 후 NS 레코드를 도메인 등록기에 등록 필요!
  # Route53 콘솔에서 NS 서버 확인:
  #   aws route53 list-resource-record-sets \
  #     --hosted-zone-id <zone-id> \
  #     --query "ResourceRecordSets[?Type=='NS']"
  # ---------------------------------------------------------------
  create_zone = true

  # ---------------------------------------------------------------
  # 도메인 이름
  # ⚠️ 실제 도메인으로 교체 필요!
  # 예시: mycompany.com, myapp.co.kr
  # ---------------------------------------------------------------
  domain_name = "example.com"

  # ---------------------------------------------------------------
  # ALB Alias 레코드
  # example.com → ALB (Alias A 레코드)
  # www.example.com → ALB (Alias A 레코드)
  # ---------------------------------------------------------------
  alb_dns_name = dependency.alb.outputs.alb_dns_name
  alb_zone_id  = dependency.alb.outputs.alb_zone_id

  # ---------------------------------------------------------------
  # 헬스 체크
  # prod: 활성화 — ALB 및 엔드포인트 상태 지속 모니터링
  #
  # ⚠️ Route53 헬스 체크 CloudWatch 알람은 us-east-1에만 생성 가능!
  #    (Route53 글로벌 서비스의 CloudWatch 메트릭은 us-east-1 전용)
  # ---------------------------------------------------------------
  enable_health_checks    = true
  health_check_path       = "/health"
  health_check_protocol   = "HTTPS"
  health_check_port       = 443

  # ---------------------------------------------------------------
  # 장애 조치 라우팅 (Failover)
  # prod: 활성화 — Primary/Secondary 레코드 구성
  #   Primary:   현재 리전 ALB
  #   Secondary: 장애 페이지(S3 Static Website) 또는 다른 리전
  # ---------------------------------------------------------------
  enable_failover        = true
  alarm_topic_arn        = dependency.cloudwatch.outputs.alarm_topic_arn

  # ---------------------------------------------------------------
  # 서브도메인 레코드 예시
  # ---------------------------------------------------------------
  # subdomains = {
  #   "api"    = { type = "A", alias_target = dependency.alb.outputs.alb_dns_name }
  #   "www"    = { type = "CNAME", value = "example.com" }
  # }
}

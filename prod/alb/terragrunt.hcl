### =============================================================================
### prod/alb/terragrunt.hcl
### PROD 환경 ALB (Application Load Balancer)
###
### 역할: 퍼블릭 서브넷에 배치된 L7 로드밸런서
###   - HTTP(80) → HTTPS(443) 자동 리다이렉트
###   - HTTPS 종단(ACM 인증서 사용)
###   - EC2 / EKS 대상 그룹으로 트래픽 분산
###   - 액세스 로그 S3 저장
###
### PROD 특징:
###   - enable_deletion_protection = true  (실수 삭제 방지)
###   - create_https_listener = true       (HTTPS 필수)
###   - enable_https_redirect = true       (HTTP → HTTPS 강제)
###   - enable_access_logs = true          (S3에 액세스 로그 저장)
###
### 의존성:
###   - vpc    → 퍼블릭 서브넷 ID
###   - s3/logs → 액세스 로그 버킷
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ ACM 인증서 ARN을 실제 값으로 교체해야 HTTPS 작동
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id              = "vpc-00000000000000000"
    public_subnet_ids   = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
    private_subnet_ids  = ["subnet-33333333333333333", "subnet-44444444444444444", "subnet-55555555555555555"]
    vpc_cidr_block      = "10.0.0.0/16"
  }
}

dependency "s3_logs" {
  config_path = "../s3/logs"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id  = "terraform-practice-prod-logs-123456789012"
    bucket_arn = "arn:aws:s3:::terraform-practice-prod-logs-123456789012"
  }
}

terraform {
  source = "../../alb/modules/alb"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 배치
  # prod: 퍼블릭 서브넷 3개 AZ에 배치 (고가용성)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.public_subnet_ids

  # ---------------------------------------------------------------
  # 삭제 방지
  # prod: true — 실수로 ALB 삭제 시 서비스 전체 중단 방지
  # dev:  false — 개발 환경 정리를 위해 비활성화
  #
  # ⚠️ 삭제하려면 콘솔에서 직접 비활성화 후 terraform destroy 실행
  # ---------------------------------------------------------------
  enable_deletion_protection = true

  # ---------------------------------------------------------------
  # HTTPS 설정
  # prod: ACM 인증서로 HTTPS 종단
  # ⚠️ ACM 인증서 ARN을 실제 값으로 교체 필요!
  #
  # ACM 인증서 발급 방법:
  #   1. AWS 콘솔 → Certificate Manager → 인증서 요청
  #   2. 도메인 소유 확인 (DNS 또는 이메일)
  #   3. 발급된 ARN 아래에 입력
  # ---------------------------------------------------------------
  create_https_listener  = true
  acm_certificate_arn    = "REPLACE_WITH_ACM_CERTIFICATE_ARN"

  # ---------------------------------------------------------------
  # HTTP → HTTPS 강제 리다이렉트
  # prod: true — 모든 HTTP 트래픽을 HTTPS로 강제 전환
  # ---------------------------------------------------------------
  enable_https_redirect = true

  # ---------------------------------------------------------------
  # 액세스 로그
  # prod: S3에 ALB 액세스 로그 저장
  #   - 보안 감사, 트래픽 분석, 장애 원인 파악에 활용
  #   - AWS가 로그를 S3에 직접 기록 (별도 비용 없음, S3 스토리지 비용만)
  # ---------------------------------------------------------------
  enable_access_logs  = true
  access_logs_bucket  = dependency.s3_logs.outputs.bucket_id

  # ---------------------------------------------------------------
  # 대상 그룹 설정
  # 헬스체크 경로는 애플리케이션의 실제 헬스체크 엔드포인트로 변경
  # ---------------------------------------------------------------
  target_port             = 8080
  health_check_path       = "/health"
  health_check_interval   = 30
  health_check_threshold  = 3
}

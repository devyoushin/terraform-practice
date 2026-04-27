### =============================================================================
### dev/alb/terragrunt.hcl
### DEV 환경 ALB (Application Load Balancer)
###
### 역할: 인터넷에서 들어오는 HTTP/HTTPS 트래픽을 백엔드 서버로 분산
###       ECS, EC2, EKS 타겟 그룹에 연결하여 사용
### DEV 특징:
###   - internal = false (인터넷 facing ALB)
###   - enable_deletion_protection = false (자유로운 삭제)
###   - create_https_listener = false (dev는 HTTP만, 인증서 불필요)
###   - enable_access_logs = false (S3 로그 비용 절약)
### 의존성: vpc
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id            = "vpc-00000000000000000"
    public_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_cidr_block    = "10.10.0.0/16"
  }
}

terraform {
  source = "../../alb/modules/alb"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # ALB는 퍼블릭 서브넷에 배포 (인터넷 트래픽 수신)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.public_subnet_ids

  # ---------------------------------------------------------------
  # ALB 타입
  # internal = false: 인터넷 facing (외부 트래픽 수신)
  # internal = true: 내부 ALB (VPC 내부 트래픽만)
  # ---------------------------------------------------------------
  internal = false

  # ---------------------------------------------------------------
  # 삭제 보호
  # dev: false (개발 중 자유로운 리소스 교체)
  # prod: true (실수 삭제 방지)
  # ---------------------------------------------------------------
  enable_deletion_protection = false

  # ---------------------------------------------------------------
  # 타겟 그룹 설정
  # target_type: instance(EC2), ip(ECS/Fargate/EKS), lambda
  # ---------------------------------------------------------------
  target_type       = "ip"
  health_check_path = "/health"

  # ---------------------------------------------------------------
  # HTTPS 리스너
  # dev: false (SSL 인증서 불필요, 개발 편의)
  # prod: true (ACM 인증서 연결 필수)
  # ---------------------------------------------------------------
  create_https_listener = false
  enable_https_redirect = false

  # ---------------------------------------------------------------
  # 액세스 로그 (S3에 저장)
  # dev: false (S3 저장 비용 절약)
  # prod: true (트래픽 분석 및 보안 감사)
  # ---------------------------------------------------------------
  enable_access_logs = false
}

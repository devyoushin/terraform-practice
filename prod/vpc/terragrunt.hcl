### =============================================================================
### prod/vpc/terragrunt.hcl
### PROD 환경 VPC (Virtual Private Cloud)
###
### 역할: 모든 AWS 리소스의 네트워크 기반
### PROD 특징:
###   - 3개 AZ 사용 (고가용성 — dev는 2개)
###   - AZ별 NAT Gateway (고가용성 — dev는 단일 NAT)
###   - VPC Flow Logs 활성화 (보안 감사 및 이상 트래픽 탐지)
###   - VPC CIDR: 10.0.0.0/16 (dev: 10.10.0.0/16 와 분리)
###   - S3 / DynamoDB VPC 엔드포인트 활성화 (비용 절감 + 보안)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
###   terraform plan -out=tfplan.binary
###   terraform show -no-color tfplan.binary > tfplan.txt
###   grep "will be destroyed" tfplan.txt
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../vpc/modules/vpc"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 설계
  # CIDR 분할 (prod: 10.0.0.0/16):
  #   퍼블릭:   10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24   (각 256개 IP)
  #   프라이빗: 10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24 (각 256개 IP)
  #
  # 퍼블릭 서브넷  → ALB, Bastion, NAT Gateway
  # 프라이빗 서브넷 → EC2, RDS, ElastiCache, EKS Worker Node
  # ---------------------------------------------------------------
  vpc_cidr = "10.0.0.0/16"

  # ---------------------------------------------------------------
  # 가용 영역 (3개 AZ)
  # prod: 3개 AZ → 고가용성 및 장애 격리
  # dev: 2개 AZ  → 비용 절약
  # ---------------------------------------------------------------
  azs = [
    "ap-northeast-2a",
    "ap-northeast-2b",
    "ap-northeast-2c",
  ]

  public_subnet_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24",
  ]

  # ---------------------------------------------------------------
  # NAT Gateway
  # prod: single_nat_gateway = false → AZ별 NAT Gateway 생성
  #        → 하나의 AZ 장애 시에도 다른 AZ 트래픽 정상 흐름
  #        → 비용 증가 but 가용성 우선
  # dev:  single_nat_gateway = true  → 1개만 생성 (비용 절약)
  # ---------------------------------------------------------------
  enable_nat_gateway = true
  single_nat_gateway = false

  # ---------------------------------------------------------------
  # VPC Endpoint (무료 Gateway 엔드포인트)
  # S3, DynamoDB 는 게이트웨이 타입 → 추가 비용 없음
  # 프라이빗 서브넷에서 인터넷 없이 AWS 서비스 접근 가능
  # ---------------------------------------------------------------
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # ---------------------------------------------------------------
  # VPC Flow Logs
  # prod: 활성화 필수 (보안 감사, 이상 트래픽 탐지, 컴플라이언스)
  # dev:  비활성화 (CloudWatch 로그 비용 절약)
  #
  # 보존 기간 90일: 일반적인 보안 감사 요구사항 충족
  # ---------------------------------------------------------------
  enable_flow_logs          = true
  flow_logs_retention_days  = 90
}

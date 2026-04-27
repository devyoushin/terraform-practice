### =============================================================================
### _envs/dev.hcl — DEV 환경 공통 변수 (참조용)
###
### 이 파일은 직접 include 하지 않습니다.
### 실제로 사용되는 환경 변수는 dev/env.hcl 에 정의되어 있습니다.
### 이 파일은 환경별 값을 한눈에 비교하기 위한 참조 문서입니다.
###
### 환경 비교:
###   dev  — VPC CIDR 10.10.0.0/16, 2개 AZ, 비용 최소화
###   prod — VPC CIDR 10.0.0.0/16,  3개 AZ, 고가용성
### =============================================================================

locals {
  environment = "dev"
  owner       = "dev-team"
  cost_center = "dev-team"

  # ── 네트워크 ──────────────────────────────────────────────────
  vpc_cidr             = "10.10.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  # ── 컴퓨팅 ───────────────────────────────────────────────────
  ec2_instance_type = "t3.micro"
  rds_instance_type = "db.t3.micro"
  cache_node_type   = "cache.t3.micro"

  # ── 보존 기간 ─────────────────────────────────────────────────
  log_retention_days    = 7
  backup_retention_days = 7
  rds_backup_retention  = 7

  # ── 기능 플래그 ───────────────────────────────────────────────
  enable_flow_logs            = false
  enable_deletion_protection  = false
  enable_performance_insights = false
  single_nat_gateway          = true   # dev: 단일 NAT (비용 절감)
  multi_az                    = false
}

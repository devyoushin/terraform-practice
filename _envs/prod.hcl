### =============================================================================
### _envs/prod.hcl — PROD 환경 공통 변수 (참조용)
###
### 이 파일은 직접 include 하지 않습니다.
### 실제로 사용되는 환경 변수는 prod/env.hcl 에 정의되어 있습니다.
### 이 파일은 환경별 값을 한눈에 비교하기 위한 참조 문서입니다.
### =============================================================================

locals {
  environment = "prod"
  owner       = "infra-team"
  cost_center = "infra-team"

  # ── 네트워크 ──────────────────────────────────────────────────
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  # ── 컴퓨팅 ───────────────────────────────────────────────────
  ec2_instance_type = "t3.medium"
  rds_instance_type = "db.t3.medium"
  cache_node_type   = "cache.r7g.large"

  # ── 보존 기간 ─────────────────────────────────────────────────
  log_retention_days    = 90
  backup_retention_days = 90
  rds_backup_retention  = 30

  # ── 기능 플래그 ───────────────────────────────────────────────
  enable_flow_logs            = true
  enable_deletion_protection  = true
  enable_performance_insights = true
  single_nat_gateway          = false  # prod: AZ별 NAT (고가용성)
  multi_az                    = true
}

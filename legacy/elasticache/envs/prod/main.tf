###
### prod 환경 - ElastiCache Redis 구성
### Primary + Replica, Multi-AZ, 스냅샷 7일, CloudWatch 로그 활성화
###

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform" }
  }
}

locals {
  environment = "prod"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    CostCenter  = "infra-team"
  }
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name        = var.project_name
  environment         = local.environment
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  # prod: 고가용성 설정
  node_type          = "cache.r7g.large"
  num_cache_clusters = 2        # Primary + Replica
  multi_az_enabled   = true

  # prod: 스냅샷 7일, 유지보수 시간 지정
  snapshot_retention_limit = 7
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "mon:04:00-mon:05:00"
  apply_immediately        = false   # 유지보수 시간에 적용

  # prod: CloudWatch 로그 활성화
  enable_logs = true

  common_tags = local.common_tags
}

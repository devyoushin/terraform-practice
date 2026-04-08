###
### staging 환경 - ElastiCache Redis 구성
### 1 노드, 스냅샷 1일 보존
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
    tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform" }
  }
}

locals {
  environment = "staging"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name        = var.project_name
  environment         = local.environment
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  node_type          = "cache.t3.small"
  num_cache_clusters = 1
  multi_az_enabled   = false

  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "mon:04:00-mon:05:00"
  apply_immediately        = false
  enable_logs              = false

  common_tags = local.common_tags
}

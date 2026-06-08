###
### dev 환경 - ElastiCache Redis 구성
### 1 노드(Primary만), 스냅샷 없음, 즉시 적용
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
    tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform" }
  }
}

locals {
  environment = "dev"
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

  # dev: 최소 사양, 단일 노드
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1
  multi_az_enabled   = false

  # dev: 스냅샷 없음, 즉시 적용
  snapshot_retention_limit = 0
  apply_immediately        = true
  enable_logs              = false

  common_tags = local.common_tags
}

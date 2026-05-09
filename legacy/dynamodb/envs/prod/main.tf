### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 DynamoDB 테이블 구성
###
### [환경 특성]
### - deletion_protection = true      : 실수로 인한 테이블 삭제 방지
### - enable_pitr = true              : 35일 이내 임의 시점 복구 가능
### - billing_mode = "PAY_PER_REQUEST": 트래픽 패턴이 불규칙한 경우 온디맨드 유지
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "infra-team" }
}

module "sessions_table" {
  source       = "../../modules/dynamodb"
  project_name = var.project_name
  environment  = "prod"
  table_suffix = "sessions"
  hash_key     = "session_id"
  billing_mode = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"
  # prod 환경: 삭제 방지 및 PITR 활성화
  deletion_protection = true
  enable_pitr         = true
  attributes          = [{ name = "session_id", type = "S" }]
  common_tags         = local.common_tags
}

module "state_lock_table" {
  source       = "../../modules/dynamodb"
  project_name = var.project_name
  environment  = "prod"
  table_suffix = "tf-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  deletion_protection = true
  enable_pitr         = true
  attributes          = [{ name = "LockID", type = "S" }]
  common_tags         = local.common_tags
}

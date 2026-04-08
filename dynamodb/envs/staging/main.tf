### envs/staging/main.tf - DynamoDB 스테이징 환경

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

module "sessions_table" {
  source        = "../../modules/dynamodb"
  project_name  = var.project_name
  environment   = "staging"
  table_suffix  = "sessions"
  hash_key      = "session_id"
  billing_mode  = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"
  attributes    = [{ name = "session_id", type = "S" }]
  common_tags   = local.common_tags
}

module "state_lock_table" {
  source       = "../../modules/dynamodb"
  project_name = var.project_name
  environment  = "staging"
  table_suffix = "tf-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attributes   = [{ name = "LockID", type = "S" }]
  common_tags  = local.common_tags
}

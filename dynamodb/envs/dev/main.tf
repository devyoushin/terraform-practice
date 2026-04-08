### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 DynamoDB 테이블 구성
###
### [환경 특성]
### - billing_mode = "PAY_PER_REQUEST" : 개발 환경에서 비용 최적화 (사용한 만큼만 과금)
### - deletion_protection = false      : 개발 중 자유로운 테이블 삭제 허용
### - enable_pitr = false              : 비용 절감
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

### -----------------------------------------------------------------------------
### 세션 테이블
### 용도: 사용자 세션 저장 (TTL로 만료된 세션 자동 삭제)
### -----------------------------------------------------------------------------
module "sessions_table" {
  source = "../../modules/dynamodb"

  project_name  = var.project_name
  environment   = "dev"
  table_suffix  = "sessions"
  hash_key      = "session_id"
  billing_mode  = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"

  attributes = [
    { name = "session_id", type = "S" }
  ]

  common_tags = local.common_tags
}

### -----------------------------------------------------------------------------
### Terraform 상태 잠금 테이블
### 용도: Terraform 원격 상태 파일 동시 수정 방지
### 파티션 키는 반드시 "LockID" (String) 이어야 합니다
### -----------------------------------------------------------------------------
module "state_lock_table" {
  source = "../../modules/dynamodb"

  project_name = var.project_name
  environment  = "dev"
  table_suffix = "tf-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    { name = "LockID", type = "S" }
  ]

  common_tags = local.common_tags
}

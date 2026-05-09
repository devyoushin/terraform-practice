###############################################
# envs/prod/main.tf
# PROD 환경 - VPC 모듈 호출
#
# prod 특이사항:
#   - 3개 AZ 사용 (고가용성)
#   - AZ별 NAT Gateway (단일 장애점 제거)
#   - VPC Flow Logs 활성화 (보안/감사)
#   - S3/DynamoDB VPC Endpoint 활성화 (보안, 비용 절감)
###############################################

provider "aws" {
  region = var.aws_region

  # prod는 계정 ID 검증 권장
  # allowed_account_ids = ["123456789012"]

  default_tags {
    tags = local.common_tags
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = "prod"
  aws_region   = var.aws_region

  # 네트워크
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # NAT: prod는 AZ별 NAT (단일 장애점 제거)
  enable_nat_gateway = true
  single_nat_gateway = false  # AZ별 NAT Gateway 생성

  # VPC Endpoint: prod는 활성화 권장
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Flow Logs: prod는 필수 활성화
  enable_flow_logs         = true
  flow_logs_retention_days = var.flow_logs_retention_days

  common_tags = local.common_tags
}

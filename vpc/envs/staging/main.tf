###############################################
# envs/staging/main.tf
# STAGING 환경 - VPC 모듈 호출
###############################################

provider "aws" {
  region = var.aws_region

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
    Environment = "staging"
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = "staging"
  aws_region   = var.aws_region

  # 네트워크
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # NAT: staging은 단일 NAT (비용 절약)
  enable_nat_gateway = true
  single_nat_gateway = true

  # VPC Endpoint (선택)
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  # Flow Logs: staging은 선택
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = 14

  common_tags = local.common_tags
}

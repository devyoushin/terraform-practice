###
### prod 환경 - Bastion Host 구성
### SSM Session Manager 전용 (SSH 포트 오픈 없음, 권장)
###

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
    }
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

module "bastion" {
  source = "../../modules/bastion"

  project_name  = var.project_name
  environment   = local.environment
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  ami_id        = var.ami_id
  instance_type = var.instance_type

  # prod: SSM Session Manager 전용 (SSH 포트 오픈 없음)
  enable_ssh = false

  common_tags = local.common_tags
}

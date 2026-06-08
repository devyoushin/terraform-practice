###############################################################################
### DEV 환경 IAM Role 모음
### - 필요한 모듈만 주석 해제하여 사용
###############################################################################

provider "aws" {
  region = var.aws_region
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

### 공통 태그
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

### EC2 인스턴스용 IAM Role (SSM + CloudWatch + S3 선택)
module "ec2_role" {
  source = "../../modules/ec2-role"

  project_name   = var.project_name
  environment    = "dev"
  s3_bucket_arns = var.s3_bucket_arns
  common_tags    = local.common_tags
}

### GitHub Actions CI/CD Role (필요 시 주석 해제)
# module "cicd_role" {
#   source = "../../modules/cicd-role"
#
#   role_name   = "${var.project_name}-dev-cicd"
#   github_org  = var.github_org
#   github_repo = var.github_repo
#   policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonECR-FullAccess",
#     "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
#   ]
#   common_tags = local.common_tags
# }

### EKS IRSA 예시 (EKS 클러스터가 있을 경우 주석 해제)
# module "app_irsa" {
#   source = "../../modules/eks-irsa"
#
#   role_name            = "${var.project_name}-dev-app-role"
#   oidc_provider_arn    = var.oidc_provider_arn
#   namespace            = "default"
#   service_account_name = "my-app"
#   policy_arns          = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
#   common_tags          = local.common_tags
# }

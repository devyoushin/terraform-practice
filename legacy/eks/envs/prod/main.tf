# ============================================================
# !! 최초 배포 시 2단계로 실행하세요 !!
#
# 1단계 - VPC와 EKS 클러스터 먼저 생성:
#   terraform apply -target=module.vpc -target=module.eks
#
# 2단계 - 나머지 전체 적용 (Karpenter 포함):
#   terraform apply
#
# prod는 3개 AZ를 사용하여 고가용성을 보장합니다.
# ============================================================

locals {
  cluster_name = "prod-eks"
  region       = var.region
}

# ============================================================
# Provider 설정
# ============================================================
provider "aws" {
  region = local.region

  # prod: 계정 ID 검증 권장 (실수 방지)
  # allowed_account_ids = ["123456789012"]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# ============================================================
# VPC (3개 AZ - 고가용성)
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  name         = "prod-vpc"
  cidr         = "10.0.0.0/16"
  cluster_name = local.cluster_name

  # prod: 3개 AZ로 고가용성 보장
  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

# ============================================================
# EKS 클러스터
# ============================================================
module "eks" {
  source = "../../modules/eks"

  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}

# ============================================================
# Karpenter (오토스케일러)
# ============================================================
module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_endpoint  = module.eks.cluster_endpoint

  depends_on = [module.eks]
}

resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  depends_on = [module.eks, module.karpenter]
}

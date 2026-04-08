# ============================================================
# !! 최초 배포 시 2단계로 실행하세요 !!
#
# 이유: helm/kubectl provider가 EKS 클러스터 정보를 참조하기 때문에
#       클러스터가 먼저 존재해야 Karpenter를 설치할 수 있습니다.
#
# 1단계 - VPC와 EKS 클러스터 먼저 생성:
#   terraform apply -target=module.vpc -target=module.eks
#
# 2단계 - 나머지 전체 적용 (Karpenter 포함):
#   terraform apply
#
# 사전 요구사항: aws CLI, kubectl 설치 필요
# ============================================================

locals {
  cluster_name = "dev-eks" # ← 클러스터 이름 (VPC 태그와 EKS 모두 이 값 사용)
  region       = var.region
}

# ============================================================
# Provider 설정
# ============================================================
provider "aws" {
  region = local.region
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
# VPC
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  name         = "dev-vpc"
  cidr         = "10.0.0.0/16"           # ← VPC CIDR 범위 (필요 시 변경)
  cluster_name = local.cluster_name

  azs             = ["ap-northeast-2a", "ap-northeast-2c"] # ← 사용할 AZ 목록
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]        # ← Private 서브넷 CIDR
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]    # ← Public 서브넷 CIDR
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

# Karpenter가 띄운 노드가 EKS 클러스터에 조인할 수 있도록 Access Entry 등록
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  depends_on = [module.eks, module.karpenter]
}

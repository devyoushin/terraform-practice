module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Karpenter가 클러스터 보안그룹을 탐지하기 위한 태그
  cluster_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"] # ← 노드 인스턴스 타입 변경 가능
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

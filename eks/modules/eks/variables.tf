variable "cluster_name" {
  type        = string
  description = "EKS 클러스터 이름"
  default     = "dev-eks" # envs/dev/main.tf의 locals.cluster_name과 일치
}

variable "vpc_id" {
  type        = string
  description = "EKS를 배포할 VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "EKS 노드를 배포할 Private 서브넷 ID 목록"
}

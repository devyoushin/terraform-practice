variable "cluster_name" {
  type        = string
  description = "EKS 클러스터 이름"
}

variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC Provider ARN (IRSA에 사용)"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS 클러스터 API 서버 엔드포인트"
}

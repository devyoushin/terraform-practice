###############################################################################
### EKS IRSA 모듈 변수 정의
###############################################################################

variable "role_name" {
  description = "생성할 IAM Role 이름"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS 클러스터의 OIDC Provider ARN"
  type        = string
}

variable "namespace" {
  description = "ServiceAccount가 위치한 Kubernetes 네임스페이스"
  type        = string
}

variable "service_account_name" {
  description = "IAM Role을 사용할 Kubernetes ServiceAccount 이름"
  type        = string
}

variable "policy_arns" {
  description = "Role에 연결할 IAM 정책 ARN 목록"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default     = {}
}

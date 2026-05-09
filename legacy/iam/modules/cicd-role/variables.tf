###############################################################################
### CI/CD Role 모듈 변수 정의
###############################################################################

variable "role_name" {
  description = "생성할 IAM Role 이름"
  type        = string
}

variable "github_org" {
  description = "GitHub 조직명 또는 개인 계정명 (예: my-org)"
  type        = string
}

variable "github_repo" {
  description = "GitHub 레포지토리 이름 (전체 허용 시 '*' 사용 가능)"
  type        = string
}

variable "create_oidc_provider" {
  description = "GitHub Actions OIDC Provider 신규 생성 여부 (이미 존재하면 false)"
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "기존 OIDC Provider ARN (create_oidc_provider = false일 때 필수)"
  type        = string
  default     = null
}

variable "policy_arns" {
  description = "Role에 연결할 IAM 정책 ARN 목록"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default     = {}
}

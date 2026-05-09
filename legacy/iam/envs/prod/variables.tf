###############################################################################
### PROD 환경 변수 정의
###############################################################################

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "s3_bucket_arns" {
  description = "EC2가 접근할 S3 버킷 ARN 목록 (비어있으면 S3 정책 미생성)"
  type        = list(string)
  default     = []
}

variable "github_org" {
  description = "GitHub 조직명 또는 개인 계정명"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub 레포지토리 이름 (전체 허용 시 '*')"
  type        = string
  default     = "*"
}

variable "oidc_provider_arn" {
  description = "EKS 클러스터의 OIDC Provider ARN"
  type        = string
  default     = ""
}

variable "oidc_provider_arn_github" {
  description = "GitHub Actions OIDC Provider ARN (기존 것 재사용 시)"
  type        = string
  default     = ""
}

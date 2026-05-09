###############################################################################
### EC2 Role 모듈 변수 정의
###############################################################################

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
}

variable "s3_bucket_arns" {
  description = "EC2가 접근할 S3 버킷 ARN 목록 (비어있으면 S3 정책 미생성)"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default     = {}
}

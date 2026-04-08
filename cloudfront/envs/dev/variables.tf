variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "dev-team"; description = "담당 팀" }
variable "s3_origin_bucket_domain" {
  description = "S3 오리진 버킷의 리전별 도메인 이름. terraform-s3 모듈의 bucket_regional_domain_name 출력값을 사용하세요."
  type        = string
  default     = ""
}

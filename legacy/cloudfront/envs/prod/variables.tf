variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "infra-team"; description = "담당 팀" }
variable "s3_origin_bucket_domain" { type = string; default = ""; description = "S3 오리진 버킷 리전별 도메인" }
variable "aliases" { type = list(string); default = []; description = "커스텀 도메인 목록 (예: [\"www.example.com\"])" }
variable "acm_certificate_arn" { type = string; default = ""; description = "ACM 인증서 ARN (us-east-1 리전에서 발급 필요)" }
variable "access_log_bucket" { type = string; default = ""; description = "액세스 로그 저장 S3 버킷 이름" }

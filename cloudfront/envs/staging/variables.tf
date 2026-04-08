variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "dev-team"; description = "담당 팀" }
variable "s3_origin_bucket_domain" { type = string; default = ""; description = "S3 오리진 버킷 도메인" }

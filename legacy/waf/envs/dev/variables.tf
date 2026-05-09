variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "dev-team"; description = "담당 팀" }
variable "alb_arn" { type = string; default = ""; description = "WAF를 연결할 ALB ARN. 비어있으면 연결 안 함." }

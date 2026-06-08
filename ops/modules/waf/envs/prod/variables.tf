variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "infra-team"; description = "담당 팀" }
variable "alb_arn" { type = string; default = ""; description = "WAF를 연결할 ALB ARN" }
variable "rate_limit" { type = number; default = 2000; description = "5분당 IP별 최대 요청 수 (DDoS 방어)" }

###
### prod 환경 - 변수 정의
###

variable "aws_region"   { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner"        { type = string; default = "infra-team"; description = "담당 팀" }

variable "vpc_id"               { type = string; description = "VPC ID" }
variable "subnet_ids"           { type = list(string); description = "프라이빗 서브넷 ID 목록 (Multi-AZ: 최소 2개)" }
variable "allowed_cidr_blocks"  { type = list(string); description = "Redis 접근 허용 CIDR 목록" }

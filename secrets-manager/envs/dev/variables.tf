variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "dev-team"; description = "담당 팀" }
variable "rds_secret_string" {
  description = "RDS 접속 정보 JSON. 기본값은 예시입니다. 반드시 실제 값으로 변경하세요."
  type        = string
  sensitive   = true
  default     = "{\"username\": \"admin\", \"password\": \"CHANGE_ME\", \"host\": \"\", \"port\": 3306, \"dbname\": \"\"}"
}

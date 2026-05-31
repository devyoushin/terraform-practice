variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "infra-team"; description = "담당 팀" }
variable "alarm_email" {
  description = "알람 수신 이메일 주소. CloudWatch 알람 발생 시 이 주소로 이메일이 발송됩니다."
  type        = string
  default     = ""
}

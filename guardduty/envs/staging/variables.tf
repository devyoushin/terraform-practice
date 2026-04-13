###############################################
# envs/staging/variables.tf
###############################################

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "owner" {
  description = "리소스 담당자 이름 또는 팀명"
  type        = string
}

variable "alert_email" {
  description = "GuardDuty 위협 알림 수신 이메일"
  type        = string
  default     = ""
}

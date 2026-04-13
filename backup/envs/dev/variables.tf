###############################################
# envs/dev/variables.tf
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

variable "resource_arns" {
  description = "백업할 리소스 ARN 목록"
  type        = list(string)
  default     = []
}

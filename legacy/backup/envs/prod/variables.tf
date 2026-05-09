###############################################
# envs/prod/variables.tf
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

variable "kms_key_arn" {
  description = "백업 볼트 암호화에 사용할 KMS 키 ARN (prod: 고객 관리형 키 권장)"
  type        = string
  default     = null
}

variable "resource_arns" {
  description = "백업할 리소스 ARN 목록"
  type        = list(string)
  default     = []
}

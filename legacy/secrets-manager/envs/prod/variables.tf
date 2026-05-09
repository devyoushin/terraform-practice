variable "aws_region" { type = string; default = "ap-northeast-2"; description = "AWS 리전" }
variable "project_name" { type = string; description = "프로젝트 이름" }
variable "owner" { type = string; default = "infra-team"; description = "담당 팀" }
variable "kms_key_arn" {
  description = "시크릿 암호화에 사용할 KMS 키 ARN. null이면 AWS 관리형 키 사용."
  type        = string
  default     = null
}

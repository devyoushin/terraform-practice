### =============================================================================
### envs/foundation/variables.tf
### Landing Zone foundation 입력값
### =============================================================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "terraform-practice"
}

variable "environment" {
  description = "Landing Zone foundation 환경명"
  type        = string
  default     = "foundation"
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "owner" {
  description = "Landing Zone 소유 팀"
  type        = string
  default     = "platform-engineering"
}

variable "create_organization" {
  description = "신규 AWS Organization을 Terraform으로 생성할지 여부"
  type        = bool
  default     = false
}

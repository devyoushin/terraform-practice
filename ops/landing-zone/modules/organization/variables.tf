### =============================================================================
### modules/organization/variables.tf
### AWS Organizations OU 및 계정 생성 입력값
### =============================================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (foundation)"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

variable "create_organization" {
  description = "신규 AWS Organization을 Terraform으로 생성할지 여부"
  type        = bool
  default     = false
}

variable "enabled_policy_types" {
  description = "Organization에 활성화할 정책 유형"
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
}

variable "root_ous" {
  description = "Root 바로 아래에 생성할 OU 목록"
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))
}

variable "child_ous" {
  description = "Root OU 아래에 생성할 2단계 OU 목록"
  type = map(object({
    name          = string
    parent_ou_key = string
    tags          = optional(map(string), {})
  }))
  default = {}
}

variable "accounts" {
  description = "생성할 AWS 계정 목록"
  type = map(object({
    name                       = string
    email                      = string
    ou_key                     = string
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    close_on_deletion          = optional(bool, false)
    iam_user_access_to_billing = optional(string, "DENY")
    tags                       = optional(map(string), {})
  }))
}

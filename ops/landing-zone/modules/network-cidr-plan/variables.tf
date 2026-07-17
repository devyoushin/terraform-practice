### =============================================================================
### modules/network-cidr-plan/variables.tf
### 서비스별 네트워크 CIDR 계획 입력값
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

variable "base_cidr" {
  description = "Public cloud 전체 CIDR"
  type        = string
  default     = "10.100.0.0/16"
}

variable "services" {
  description = "서비스별 CIDR 할당 입력값"
  type = map(object({
    name        = string
    domain      = string
    index       = number
    owner       = string
    criticality = string
  }))
}

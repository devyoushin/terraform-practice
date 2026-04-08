### =============================================================================
### modules/secrets-manager/variables.tf
### =============================================================================

variable "project_name" {
  description = "프로젝트 이름."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능합니다."
  }
}

variable "environment" {
  description = "배포 환경."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "secret_suffix" {
  description = "시크릿 용도를 나타내는 접미사. (예: rds, api-key, jwt-secret)"
  type        = string
}

variable "secret_name" {
  description = "시크릿 이름 직접 지정. null이면 {project}/{environment}/{secret_suffix} 형식으로 자동 생성됩니다."
  type        = string
  default     = null
}

variable "description" {
  description = "시크릿에 대한 설명."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "암호화에 사용할 KMS 키 ARN. null이면 AWS 관리형 키 사용."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "시크릿 삭제 후 복구 가능 기간. 0이면 즉시 삭제(dev 권장), 7~30이면 복구 대기(prod 권장)."
  type        = number
  default     = 30
}

variable "secret_string" {
  description = "시크릿 초기값 (JSON 형식 권장). 설정 후 Terraform이 변경을 무시합니다. sensitive로 처리됩니다."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_rotation" {
  description = "자동 교체 활성화 (Lambda 함수 필요)."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "자동 교체에 사용할 Lambda 함수 ARN. enable_rotation = true일 때 필수."
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "자동 교체 주기 (일)."
  type        = number
  default     = 30
}

variable "secret_policy_json" {
  description = "시크릿 접근 정책 JSON. 빈 문자열이면 정책을 생성하지 않습니다."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

### =============================================================================
### modules/kms/variables.tf
### KMS 모듈 입력 변수 정의
### =============================================================================

variable "project_name" {
  description = "프로젝트 이름. KMS 키 설명 및 별칭 자동 생성 시 사용됩니다."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능하며 3~63자여야 합니다."
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

variable "key_suffix" {
  description = "키 용도를 나타내는 접미사. 별칭 자동 생성 시 사용됩니다. (예: rds, s3, eks, app)"
  type        = string
}

variable "key_alias" {
  description = "KMS 키 별칭을 직접 지정할 경우 사용합니다. null이면 alias/{project_name}-{environment}-{key_suffix} 형식으로 자동 생성됩니다."
  type        = string
  default     = null
}

variable "key_usage" {
  description = "키 사용 목적. ENCRYPT_DECRYPT(암호화/복호화) 또는 SIGN_VERIFY(서명/검증)."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
    error_message = "key_usage는 ENCRYPT_DECRYPT 또는 SIGN_VERIFY이어야 합니다."
  }
}

variable "key_spec" {
  description = "키 스펙. SYMMETRIC_DEFAULT(대칭키), RSA_2048, RSA_4096, ECC_NIST_P256 등. 일반 암호화에는 SYMMETRIC_DEFAULT 권장."
  type        = string
  default     = "SYMMETRIC_DEFAULT"
}

variable "deletion_window_in_days" {
  description = "키 삭제 예약 후 실제 삭제까지의 대기 기간 (7~30일). prod 환경에서는 30일 권장."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days는 7 이상 30 이하여야 합니다."
  }
}

variable "enable_key_rotation" {
  description = "자동 키 교체 활성화 (대칭키만 지원). true로 설정하면 연 1회 자동으로 키 교체됩니다. 보안 규정 준수를 위해 true 권장."
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "멀티 리전 키 활성화 여부. true로 설정하면 다른 리전에 복제키 생성 가능. 재해 복구(DR) 시나리오에서 사용."
  type        = bool
  default     = false
}

variable "key_policy_json" {
  description = "KMS 키 정책 JSON 문자열. 빈 문자열이면 AWS 기본 정책(계정 루트 전체 권한)을 사용합니다."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

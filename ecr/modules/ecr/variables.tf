### =============================================================================
### modules/ecr/variables.tf
### ECR 모듈 입력 변수 정의
### =============================================================================

### -----------------------------------------------------------------------------
### 필수 변수
### -----------------------------------------------------------------------------

variable "project_name" {
  description = "프로젝트 이름. 레포지토리 이름 자동 생성 시 사용됩니다."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능하며 3~63자여야 합니다."
  }
}

variable "environment" {
  description = "배포 환경. 레포지토리 이름 자동 생성 및 태그에 사용됩니다."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
  }
}

variable "name_suffix" {
  description = "레포지토리 이름 접미사. 자동 생성 시 사용됩니다. (예: app, api, worker)"
  type        = string
}

### -----------------------------------------------------------------------------
### 선택 변수 - 레포지토리 기본 설정
### -----------------------------------------------------------------------------

variable "repository_name" {
  description = "레포지토리 이름을 직접 지정할 경우 사용합니다. null이면 {project_name}-{environment}-{name_suffix} 형식으로 자동 생성됩니다."
  type        = string
  default     = null
}

variable "image_tag_mutability" {
  description = "이미지 태그 변경 가능 여부. MUTABLE(변경 가능, dev 권장) 또는 IMMUTABLE(변경 불가, prod 권장 - 불변성 보장)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability는 MUTABLE 또는 IMMUTABLE이어야 합니다."
  }
}

variable "scan_on_push" {
  description = "이미지 푸시 시 취약점 자동 스캔 여부. 보안을 위해 모든 환경에서 true 권장."
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "true로 설정하면 이미지가 있어도 terraform destroy 시 레포지토리를 강제 삭제합니다. prod 환경에서는 false 권장."
  type        = bool
  default     = false
}

### -----------------------------------------------------------------------------
### 선택 변수 - 암호화
### -----------------------------------------------------------------------------

variable "encryption_type" {
  description = "레포지토리 암호화 타입. AES256(AWS 관리형 키) 또는 KMS(고객 관리형 키). KMS 선택 시 kms_key_arn 필수."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type은 AES256 또는 KMS이어야 합니다."
  }
}

variable "kms_key_arn" {
  description = "KMS 암호화에 사용할 키 ARN. encryption_type = 'KMS'일 때만 사용됩니다."
  type        = string
  default     = null
}

### -----------------------------------------------------------------------------
### 선택 변수 - 수명주기 정책
### -----------------------------------------------------------------------------

variable "enable_lifecycle_policy" {
  description = "이미지 수명주기 정책 활성화 여부. true로 설정하면 오래된 이미지를 자동으로 삭제하여 스토리지 비용을 절감합니다."
  type        = bool
  default     = true
}

variable "untagged_image_days" {
  description = "태그 없는 이미지를 삭제하기까지의 보관 일수. 빌드 실패 등으로 생성된 불필요한 이미지를 정리합니다."
  type        = number
  default     = 14
}

variable "tagged_image_count" {
  description = "태그 있는 이미지를 최대 몇 개까지 유지할지 설정합니다. 이 수를 초과하는 오래된 이미지는 자동 삭제됩니다."
  type        = number
  default     = 30
}

### -----------------------------------------------------------------------------
### 선택 변수 - 레포지토리 정책
### -----------------------------------------------------------------------------

variable "repository_policy_json" {
  description = "레포지토리 접근 정책 JSON 문자열. 빈 문자열이면 정책을 생성하지 않습니다. 크로스 계정 접근 허용 시 사용합니다."
  type        = string
  default     = ""
}

### -----------------------------------------------------------------------------
### 선택 변수 - 태그
### -----------------------------------------------------------------------------

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵. 환경별 main.tf의 locals.common_tags를 전달하세요."
  type        = map(string)
  default     = {}
}

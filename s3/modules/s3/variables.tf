### =============================================================================
### modules/s3/variables.tf
### S3 모듈 입력 변수 정의
### =============================================================================

### -----------------------------------------------------------------------------
### 필수 변수
### -----------------------------------------------------------------------------

variable "project_name" {
  description = "프로젝트 이름. 버킷 이름 자동 생성 시 사용됩니다."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능하며 3~63자여야 합니다."
  }
}

variable "environment" {
  description = "배포 환경. 버킷 이름 자동 생성 및 태그에 사용됩니다."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
  }
}

variable "bucket_suffix" {
  description = "버킷 용도를 나타내는 접미사. 버킷 이름 자동 생성 시 사용됩니다. (예: assets, logs, backup, tfstate)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_suffix))
    error_message = "bucket_suffix는 소문자, 숫자, 하이픈만 사용 가능합니다."
  }
}

### -----------------------------------------------------------------------------
### 선택 변수 - 버킷 기본 설정
### -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "버킷 이름을 직접 지정할 경우 사용합니다. null이면 {project_name}-{environment}-{bucket_suffix} 형식으로 자동 생성됩니다."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "true로 설정하면 버킷 내 객체가 있어도 terraform destroy 시 버킷을 강제 삭제합니다. prod 환경에서는 false 권장."
  type        = bool
  default     = false
}

### -----------------------------------------------------------------------------
### 선택 변수 - 버전관리
### -----------------------------------------------------------------------------

variable "enable_versioning" {
  description = "버킷 버전관리 활성화 여부. true = Enabled, false = Suspended. 중요 데이터가 있는 버킷은 true 권장."
  type        = bool
  default     = true
}

### -----------------------------------------------------------------------------
### 선택 변수 - 암호화
### -----------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "서버 사이드 암호화에 사용할 KMS 키 ARN. null이면 S3 관리형 키(AES256)를 사용합니다."
  type        = string
  default     = null
}

### -----------------------------------------------------------------------------
### 선택 변수 - 수명주기
### -----------------------------------------------------------------------------

variable "enable_lifecycle" {
  description = "수명주기 규칙 활성화 여부. true로 설정하면 이전 버전 자동 전환(30일→STANDARD_IA) 및 삭제(90일), 미완성 멀티파트 업로드 정리(7일) 규칙이 적용됩니다."
  type        = bool
  default     = false
}

### -----------------------------------------------------------------------------
### 선택 변수 - 버킷 정책
### -----------------------------------------------------------------------------

variable "bucket_policy_json" {
  description = "버킷에 적용할 IAM 정책 JSON 문자열. 빈 문자열(\"\")이면 버킷 정책을 생성하지 않습니다. jsonencode() 또는 file()로 전달 가능."
  type        = string
  default     = ""
}

### -----------------------------------------------------------------------------
### 선택 변수 - CORS
### -----------------------------------------------------------------------------

variable "cors_rules" {
  description = "CORS 규칙 목록. 비어있으면 CORS 설정을 생성하지 않습니다. 웹 애플리케이션에서 S3 직접 업로드 시 필요합니다."
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3000)
  }))
  default = []
}

### -----------------------------------------------------------------------------
### 선택 변수 - 태그
### -----------------------------------------------------------------------------

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵. 환경별 main.tf의 locals.common_tags를 전달하세요."
  type        = map(string)
  default     = {}
}

### =============================================================================
### modules/dynamodb/variables.tf
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
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
  }
}

variable "table_suffix" {
  description = "테이블 용도를 나타내는 접미사. (예: sessions, locks, events)"
  type        = string
}

variable "table_name" {
  description = "테이블 이름 직접 지정. null이면 {project_name}-{environment}-{table_suffix} 형식으로 자동 생성됩니다."
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "빌링 모드. PAY_PER_REQUEST(온디맨드, 트래픽 패턴이 불규칙할 때) 또는 PROVISIONED(예측 가능한 트래픽, 비용 절감). dev/staging에는 PAY_PER_REQUEST 권장."
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode는 PAY_PER_REQUEST 또는 PROVISIONED이어야 합니다."
  }
}

variable "read_capacity" {
  description = "PROVISIONED 모드 읽기 용량 (RCU). billing_mode = PROVISIONED일 때만 사용됩니다."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "PROVISIONED 모드 쓰기 용량 (WCU). billing_mode = PROVISIONED일 때만 사용됩니다."
  type        = number
  default     = 5
}

variable "hash_key" {
  description = "파티션 키 이름 (테이블 기본 키). 테이블 생성 후 변경 불가."
  type        = string
}

variable "range_key" {
  description = "정렬 키 이름. 빈 문자열이면 정렬 키 없음. 테이블 생성 후 변경 불가."
  type        = string
  default     = ""
}

variable "attributes" {
  description = "테이블 속성 정의 목록. 파티션 키, 정렬 키, GSI에서 사용하는 속성만 정의합니다. type: S(문자열), N(숫자), B(바이너리)"
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "GSI(Global Secondary Index) 정의 목록."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    read_capacity      = optional(number, 5)
    write_capacity     = optional(number, 5)
    non_key_attributes = optional(list(string), [])
  }))
  default = []
}

variable "deletion_protection" {
  description = "테이블 삭제 방지 활성화. prod 환경에서 true 권장."
  type        = bool
  default     = false
}

variable "enable_stream" {
  description = "DynamoDB Streams 활성화. Lambda 트리거나 이벤트 기반 아키텍처에서 사용."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "스트림 레코드에 포함할 정보. NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES, KEYS_ONLY 중 선택."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "enable_pitr" {
  description = "Point-in-Time Recovery 활성화. true로 설정하면 35일 이내 임의 시점으로 복구 가능. prod 권장."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "서버 사이드 암호화 KMS 키 ARN. null이면 DynamoDB 관리형 키 사용."
  type        = string
  default     = null
}

variable "ttl_attribute" {
  description = "TTL 속성 이름. 이 속성에 저장된 Unix 타임스탬프가 지나면 항목이 자동 삭제됩니다. 빈 문자열이면 TTL 비활성화."
  type        = string
  default     = ""
}

variable "enable_autoscaling" {
  description = "자동 스케일링 활성화. PROVISIONED 모드에서만 사용 가능."
  type        = bool
  default     = false
}

variable "autoscaling_read_min" { type = number; default = 5; description = "읽기 최소 용량" }
variable "autoscaling_read_max" { type = number; default = 100; description = "읽기 최대 용량" }
variable "autoscaling_read_target" { type = number; default = 70.0; description = "읽기 목표 사용률 (%)" }
variable "autoscaling_write_min" { type = number; default = 5; description = "쓰기 최소 용량" }
variable "autoscaling_write_max" { type = number; default = 100; description = "쓰기 최대 용량" }
variable "autoscaling_write_target" { type = number; default = 70.0; description = "쓰기 목표 사용률 (%)" }

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

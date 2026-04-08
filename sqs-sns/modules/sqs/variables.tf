### ============================================================
### modules/sqs/variables.tf
### SQS 모듈 입력 변수 정의
### ============================================================

### 프로젝트 기본 정보

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 변수는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### 큐 기본 설정

variable "queue_name" {
  description = "SQS 큐 이름 (FIFO 큐의 경우 .fifo 접미사가 자동 추가됨)"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "메시지 가시성 타임아웃 (초) - 컨슈머가 메시지를 처리하는 최대 시간"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "메시지 보존 기간 (초) - dev: 86400(1일) / staging: 86400(1일) / prod: 604800(7일)"
  type        = number
  default     = 86400 # 1일

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds는 60초(1분) ~ 1209600초(14일) 사이여야 합니다."
  }
}

variable "max_message_size" {
  description = "최대 메시지 크기 (바이트) - 기본값: 262144 (256KB)"
  type        = number
  default     = 262144 # 256KB

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size는 1024(1KB) ~ 262144(256KB) 사이여야 합니다."
  }
}

variable "delay_seconds" {
  description = "메시지 전송 지연 시간 (초) - 큐에 추가된 메시지가 컨슈머에게 노출되기까지의 지연"
  type        = number
  default     = 0
}

### DLQ(Dead Letter Queue) 설정

variable "max_receive_count" {
  description = "DLQ로 이동하기 전 최대 수신 횟수 - dev: 3 / prod: 5"
  type        = number
  default     = 3
}

### FIFO 큐 설정

variable "fifo_queue" {
  description = "FIFO 큐 활성화 여부 (순서 보장 및 중복 제거 지원)"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "콘텐츠 기반 중복 제거 활성화 여부 (fifo_queue = true 일 때만 유효)"
  type        = bool
  default     = false
}

### 암호화 설정

variable "kms_master_key_id" {
  description = "KMS 마스터 키 ID (SSE-KMS 암호화용) - null이면 SSE-SQS 기본 암호화 사용"
  type        = string
  default     = null
}

### SNS 연동 설정

variable "sns_topic_arns" {
  description = "이 SQS 큐에 메시지를 게시할 수 있는 SNS 토픽 ARN 목록 (큐 정책 자동 생성)"
  type        = list(string)
  default     = []
}

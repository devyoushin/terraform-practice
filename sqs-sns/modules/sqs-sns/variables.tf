### =============================================================================
### modules/sqs-sns/variables.tf
### SQS-SNS 모듈 입력 변수 정의
### =============================================================================

### -----------------------------------------------------------------------------
### 필수 변수
### -----------------------------------------------------------------------------

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용). 소문자, 숫자, 하이픈만 허용."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능하며 3~63자여야 합니다."
  }
}

variable "environment" {
  description = "배포 환경. 리소스 명명 및 태그에 사용됩니다."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "queue_name" {
  description = "SQS 큐 이름 식별자. 실제 큐 이름은 {project_name}-{environment}-{queue_name} 형식으로 생성됩니다."
  type        = string
}

variable "topic_name" {
  description = "SNS 토픽 이름 식별자. 실제 토픽 이름은 {project_name}-{environment}-{topic_name} 형식으로 생성됩니다."
  type        = string
}

### -----------------------------------------------------------------------------
### 선택 변수 - SQS 메인 큐 설정
### -----------------------------------------------------------------------------

variable "visibility_timeout_seconds" {
  description = "메시지 가시성 타임아웃 (초). 컨슈머가 메시지를 처리하는 최대 예상 시간보다 길게 설정. dev: 30초, prod: 300초 권장."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds는 0 ~ 43200초 사이여야 합니다."
  }
}

variable "message_retention_seconds" {
  description = "메시지 보존 기간 (초). dev: 345600(4일), staging: 604800(7일), prod: 1209600(14일) 권장."
  type        = number
  default     = 345600 # 4일

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds는 60초(1분) ~ 1209600초(14일) 사이여야 합니다."
  }
}

variable "max_message_size" {
  description = "최대 메시지 크기 (바이트). 기본값 262144 = 256KB (SQS 최대값)."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size는 1024(1KB) ~ 262144(256KB) 사이여야 합니다."
  }
}

variable "delay_seconds" {
  description = "메시지 전달 지연 시간 (초). 큐에 추가된 메시지가 컨슈머에게 보이기까지의 지연. FIFO 큐는 0 고정."
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Long Polling 대기 시간 (초). 0이면 Short Polling, 1~20이면 Long Polling. 비용 절감을 위해 20 권장."
  type        = number
  default     = 20

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "receive_wait_time_seconds는 0 ~ 20초 사이여야 합니다."
  }
}

### -----------------------------------------------------------------------------
### 선택 변수 - DLQ 설정
### -----------------------------------------------------------------------------

variable "max_receive_count" {
  description = "메시지가 DLQ로 이동하기 전 최대 수신 횟수. dev: 3, prod: 5 권장."
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count는 1 ~ 1000 사이여야 합니다."
  }
}

variable "dlq_message_retention_seconds" {
  description = "DLQ 메시지 보존 기간 (초). 메인 큐보다 길게 설정하여 재처리/분석 시간 확보. 기본값: 1209600(14일)."
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "dlq_message_retention_seconds는 60초(1분) ~ 1209600초(14일) 사이여야 합니다."
  }
}

### -----------------------------------------------------------------------------
### 선택 변수 - FIFO 큐 설정
### -----------------------------------------------------------------------------

variable "fifo_queue" {
  description = "메인 큐를 FIFO 큐로 생성할지 여부. true이면 순서 보장 및 정확히 1회 처리 지원. 한번 생성 후 변경 불가."
  type        = bool
  default     = false
}

variable "enable_fifo_queue" {
  description = "메인 큐(표준)와 별도로 FIFO 큐를 추가 생성할지 여부. fifo_queue = false 일 때만 유효."
  type        = bool
  default     = false
}

variable "fifo_topic" {
  description = "SNS 토픽을 FIFO 토픽으로 생성할지 여부. FIFO SQS 큐 구독 시 true 설정 필요."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "콘텐츠 기반 중복 제거 활성화 여부. fifo_queue = true 또는 fifo_topic = true 일 때만 유효."
  type        = bool
  default     = false
}

### -----------------------------------------------------------------------------
### 선택 변수 - 암호화 설정
### -----------------------------------------------------------------------------

variable "kms_master_key_id" {
  description = "KMS 마스터 키 ID 또는 ARN (SSE-KMS 암호화용). null이면 SSE-SQS 기본 암호화 사용. prod 환경에서 고객 관리형 KMS 키 사용 권장."
  type        = string
  default     = null
}

### -----------------------------------------------------------------------------
### 선택 변수 - SNS 구독 설정
### -----------------------------------------------------------------------------

variable "email_subscriptions" {
  description = "SNS 토픽의 이메일 구독 목록. 구독 확인 이메일이 각 주소로 발송됩니다."
  type        = list(string)
  default     = []
}

variable "lambda_subscription_arns" {
  description = "SNS 토픽을 구독할 Lambda 함수 ARN 목록."
  type        = list(string)
  default     = []
}

variable "https_subscription_urls" {
  description = "SNS 토픽을 구독할 HTTPS 엔드포인트 URL 목록."
  type        = list(string)
  default     = []
}

variable "sqs_raw_message_delivery" {
  description = "SQS 구독의 Raw Message Delivery 활성화 여부. true이면 SNS 래퍼(JSON 메타데이터) 없이 순수 메시지만 전달."
  type        = bool
  default     = false
}

variable "sns_filter_policy" {
  description = "SNS 메시지 필터 정책 JSON 문자열. 빈 문자열이면 필터링 없이 모든 메시지 전달."
  type        = string
  default     = ""
}

variable "sns_filter_policy_scope" {
  description = "SNS 필터 정책 적용 범위. MessageAttributes(기본) 또는 MessageBody."
  type        = string
  default     = "MessageAttributes"

  validation {
    condition     = contains(["MessageAttributes", "MessageBody"], var.sns_filter_policy_scope)
    error_message = "sns_filter_policy_scope는 MessageAttributes 또는 MessageBody 중 하나여야 합니다."
  }
}

variable "sns_delivery_policy" {
  description = "SNS 토픽 전송 정책 JSON 문자열 (재시도 횟수, 지연 설정 등). 빈 문자열이면 AWS 기본값 사용."
  type        = string
  default     = ""
}

### -----------------------------------------------------------------------------
### 선택 변수 - CloudWatch 알람 설정
### -----------------------------------------------------------------------------

variable "enable_cloudwatch_alarms" {
  description = "CloudWatch 알람 활성화 여부. staging/prod 환경에서 활성화 권장."
  type        = bool
  default     = false
}

variable "queue_depth_alarm_threshold" {
  description = "메인 큐 깊이 알람 임계값 (메시지 수). 이 수치 이상 쌓이면 알람 발생."
  type        = number
  default     = 100
}

variable "alarm_evaluation_periods" {
  description = "알람 평가 기간 수. evaluation_periods * period 시간 동안 임계값을 초과하면 알람 발생."
  type        = number
  default     = 2
}

variable "alarm_sns_topic_arns" {
  description = "CloudWatch 알람 발생 시 알림을 받을 SNS 토픽 ARN 목록."
  type        = list(string)
  default     = []
}

### -----------------------------------------------------------------------------
### 선택 변수 - 태그
### -----------------------------------------------------------------------------

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

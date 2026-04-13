### =============================================================================
### envs/staging/variables.tf
### 스테이징(staging) 환경 입력 변수 정의
### =============================================================================

variable "aws_region" {
  description = "AWS 리소스를 배포할 리전. 기본값: 서울 리전(ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름. 리소스 이름 자동 생성 패턴에 사용됩니다: {project_name}-staging-{queue_name}"
  type        = string
}

variable "owner" {
  description = "리소스 소유자 또는 담당 팀. 태그에 사용됩니다."
  type        = string
  default     = "infra-team"
}

variable "queue_name" {
  description = "SQS 큐 이름 식별자 (예: orders, notifications, events)"
  type        = string
  default     = "events"
}

variable "topic_name" {
  description = "SNS 토픽 이름 식별자 (예: app-events, alerts)"
  type        = string
  default     = "app-events"
}

variable "enable_fifo_queue" {
  description = "추가 FIFO 큐 생성 여부. prod 배포 전 FIFO 동작 사전 검증용."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS 키 ID 또는 ARN. null이면 SSE-SQS 기본 암호화 사용. prod 배포 전 KMS 동작 검증 시 지정."
  type        = string
  default     = null
}

variable "email_subscriptions" {
  description = "SNS 토픽 이메일 구독 목록. 스테이징 알림 수신 주소."
  type        = list(string)
  default     = []
}

variable "queue_depth_alarm_threshold" {
  description = "큐 깊이 알람 임계값 (메시지 수). 이 수치 이상 쌓이면 알람 발생."
  type        = number
  default     = 100
}

variable "alarm_sns_topic_arns" {
  description = "CloudWatch 알람 알림을 받을 SNS 토픽 ARN 목록."
  type        = list(string)
  default     = []
}

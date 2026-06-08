### =============================================================================
### envs/prod/variables.tf
### 운영(prod) 환경 입력 변수 정의
### =============================================================================

variable "aws_region" {
  description = "AWS 리소스를 배포할 리전. 기본값: 서울 리전(ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름. 리소스 이름 자동 생성 패턴에 사용됩니다: {project_name}-prod-{queue_name}"
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
  description = "추가 FIFO 큐 생성 여부. 순서 보장이 필요한 워크로드(주문 처리, 금융 트랜잭션 등)에 사용."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS 키 ID 또는 ARN. prod 환경에서는 고객 관리형 KMS 키 사용 필수."
  type        = string
}

variable "email_subscriptions" {
  description = "SNS 토픽 이메일 구독 목록. 운영팀 알림 수신 주소."
  type        = list(string)
  default     = []
}

variable "lambda_subscription_arns" {
  description = "SNS 토픽을 구독할 Lambda 함수 ARN 목록."
  type        = list(string)
  default     = []
}

variable "queue_depth_alarm_threshold" {
  description = "큐 깊이 알람 임계값 (메시지 수). 이 수치 이상 쌓이면 알람 발생."
  type        = number
  default     = 1000
}

variable "alarm_sns_topic_arns" {
  description = "CloudWatch 알람 알림을 받을 SNS 토픽 ARN 목록."
  type        = list(string)
  default     = []
}

variable "sqs_raw_message_delivery" {
  description = "SQS 구독의 Raw Message Delivery 활성화 여부."
  type        = bool
  default     = false
}

variable "sns_filter_policy" {
  description = "SNS 메시지 필터 정책 JSON 문자열. 빈 문자열이면 필터링 없이 모든 메시지 전달."
  type        = string
  default     = ""
}

variable "sns_filter_policy_scope" {
  description = "SNS 필터 정책 적용 범위. MessageAttributes 또는 MessageBody."
  type        = string
  default     = "MessageAttributes"
}

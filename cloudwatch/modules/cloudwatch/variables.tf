### =============================================================================
### modules/cloudwatch/variables.tf
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

variable "kms_key_arn" {
  description = "로그 그룹 암호화 KMS 키 ARN. null이면 AWS 관리형 키 사용."
  type        = string
  default     = null
}

variable "enable_alarm_notification" {
  description = "알람 알림 활성화 여부. true로 설정하면 SNS 토픽을 생성하고 알람 발생 시 알림을 보냅니다."
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "알람 수신 이메일 주소. enable_alarm_notification = true일 때 사용됩니다."
  type        = string
  default     = ""
}

variable "log_groups" {
  description = "생성할 CloudWatch 로그 그룹 목록."
  type = list(object({
    name           = string
    retention_days = optional(number, 30)
  }))
  default = []
}

variable "metric_alarms" {
  description = "생성할 CloudWatch 메트릭 알람 목록."
  type = list(object({
    alarm_name          = string
    description         = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "missing")
  }))
  default = []
}

variable "enable_dashboard" {
  description = "CloudWatch 대시보드 생성 여부. true로 설정하면 EC2, RDS, ALB 메트릭 대시보드를 생성합니다."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

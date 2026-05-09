### ============================================================
### modules/guardduty/variables.tf
### GuardDuty 모듈 입력 변수 정의
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
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment 변수는 dev, prod 중 하나여야 합니다."
  }
}

### 공통 태그

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### GuardDuty 활성화 설정

variable "enable_guardduty" {
  description = "GuardDuty 탐지기 활성화 여부"
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "GuardDuty 위협 인텔리전스 결과 발행 주기 (FIFTEEN_MINUTES / ONE_HOUR / SIX_HOURS)"
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "finding_publishing_frequency는 FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS 중 하나여야 합니다."
  }
}

### 데이터 소스 보호 설정

variable "enable_s3_logs" {
  description = "S3 로그 기반 위협 탐지 활성화 여부 (S3 데이터 이벤트 모니터링)"
  type        = bool
  default     = true
}

variable "enable_kubernetes_audit_logs" {
  description = "Kubernetes 감사 로그 위협 탐지 활성화 여부 (EKS 환경에서 사용)"
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "EC2 인스턴스 악성코드 탐지 활성화 여부 (추가 비용 발생)"
  type        = bool
  default     = false
}

### 알림 설정

variable "alert_email" {
  description = "GuardDuty 위협 알림 수신 이메일 주소 (SNS 구독용, 빈 값이면 이메일 구독 생략)"
  type        = string
  default     = ""
}

variable "min_severity" {
  description = "CloudWatch 이벤트 알림 최소 심각도 (1-10, 기본값 4 = Medium 이상)"
  type        = number
  default     = 4

  validation {
    condition     = var.min_severity >= 1 && var.min_severity <= 10
    error_message = "min_severity는 1~10 사이의 값이어야 합니다. (1-3: Low / 4-6: Medium / 7-8: High / 9-10: Critical)"
  }
}

### 필터 설정

variable "enable_filter" {
  description = "GuardDuty 결과 필터 활성화 여부 (특정 IP/도메인 제외 등 커스텀 필터링)"
  type        = bool
  default     = false
}

variable "filter_trusted_ips" {
  description = "GuardDuty 탐지에서 제외할 신뢰 IP 목록 (내부 보안 스캐너, 허용된 감사 도구 등)"
  type        = list(string)
  default     = []
}

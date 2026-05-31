###############################################
# envs/prod/variables.tf
###############################################

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "owner" {
  description = "리소스 담당자 이름 또는 팀명"
  type        = string
}

variable "alert_email" {
  description = "GuardDuty 위협 알림 수신 이메일"
  type        = string
  default     = ""
}

variable "enable_kubernetes_audit_logs" {
  description = "Kubernetes 감사 로그 위협 탐지 활성화 (EKS 사용 시 true)"
  type        = bool
  default     = false
}

variable "filter_trusted_ips" {
  description = "GuardDuty 탐지에서 제외할 신뢰 IP 목록 (내부 보안 스캐너 등)"
  type        = list(string)
  default     = []
}

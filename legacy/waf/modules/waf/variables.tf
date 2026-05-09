### =============================================================================
### modules/waf/variables.tf
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

variable "scope" {
  description = "WAF 적용 범위. REGIONAL(ALB/API Gateway용) 또는 CLOUDFRONT(CloudFront용, us-east-1 리전에서 생성 필요)."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope는 REGIONAL 또는 CLOUDFRONT이어야 합니다."
  }
}

variable "default_action" {
  description = "기본 동작. allow(허용, 블랙리스트 방식) 또는 block(차단, 화이트리스트 방식)."
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action은 allow 또는 block이어야 합니다."
  }
}

variable "managed_rules_action" {
  description = "AWS 관리형 규칙 동작. none(실제 차단) 또는 count(모니터링만, 오탐 확인 시 사용)."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "count"], var.managed_rules_action)
    error_message = "managed_rules_action은 none 또는 count이어야 합니다."
  }
}

variable "enable_rate_limiting" {
  description = "IP 기반 요청 수 제한 활성화. DDoS 방어를 위해 prod 환경에서 권장."
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "5분당 IP별 최대 요청 수. 이 수를 초과하면 차단됩니다. (최소값: 100)"
  type        = number
  default     = 2000
}

variable "blocked_ip_addresses" {
  description = "차단할 IP 주소 목록 (CIDR 형식). 예: [\"1.2.3.4/32\", \"10.0.0.0/8\"]"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "허용할 IP 주소 목록 (CIDR 형식). default_action = 'block'일 때 화이트리스트로 사용."
  type        = list(string)
  default     = []
}

variable "resource_arn" {
  description = "WAF를 연결할 ALB 또는 API Gateway ARN. 비어있으면 연결하지 않습니다. CloudFront 연결은 배포 설정에서 직접."
  type        = string
  default     = ""
}

variable "log_destination_arn" {
  description = "WAF 로그 저장 대상 ARN. Kinesis Data Firehose 또는 CloudWatch Logs ARN."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

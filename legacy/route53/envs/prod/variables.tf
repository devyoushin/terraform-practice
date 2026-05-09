### =============================================================================
### envs/prod/variables.tf
### 운영(prod) 환경 입력 변수 정의
### =============================================================================

### AWS 기본 설정

variable "aws_region" {
  description = "AWS 리소스를 배포할 리전. 기본값: 서울 리전(ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

### 프로젝트 정보

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "owner" {
  description = "리소스 소유자 또는 팀 이름 (태그에 사용)"
  type        = string
  default     = "infra-team"
}

### 호스팅 존 설정

variable "create_zone" {
  description = "퍼블릭 호스팅 존 신규 생성 여부. false이면 기존 존 참조."
  type        = bool
  default     = true
}

variable "zone_name" {
  description = "Route53 호스팅 존 도메인 이름 (prod 환경: 루트 도메인, 예: example.com)"
  type        = string
}

### DNS 레코드 설정

variable "records" {
  description = "퍼블릭 존 DNS 레코드 맵 (모듈 variables.tf 참고)"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}

### 프라이빗 존 설정

variable "enable_private_zone" {
  description = "프라이빗 호스팅 존 활성화 여부. 내부 서비스 디스커버리에 사용."
  type        = bool
  default     = false
}

variable "private_zone_name" {
  description = "프라이빗 호스팅 존 도메인 이름. 빈 문자열이면 internal.{zone_name} 자동 생성."
  type        = string
  default     = ""
}

variable "private_zone_vpc_ids" {
  description = "프라이빗 존과 연결할 VPC ID 목록"
  type        = list(string)
  default     = []
}

variable "private_records" {
  description = "프라이빗 존 DNS 레코드 맵"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}

### 헬스 체크 설정

variable "health_checks" {
  description = "헬스 체크 설정 맵 (모듈 variables.tf 참고). prod에서는 모든 주요 엔드포인트 등록 권장."
  type = map(object({
    fqdn              = string
    port              = number
    type              = string
    resource_path     = string
    failure_threshold = optional(number, 3)
    request_interval  = optional(number, 30)
    regions           = optional(list(string))
  }))
  default = {}
}

### 페일오버 라우팅 설정

variable "enable_failover_routing" {
  description = "페일오버 라우팅 활성화 여부. prod 환경에서 고가용성을 위해 true 권장."
  type        = bool
  default     = true
}

variable "failover_records" {
  description = "페일오버 라우팅 레코드 설정 맵 (모듈 variables.tf 참고)"
  type = map(object({
    name             = string
    type             = string
    ttl              = optional(number, 60)
    primary_records  = optional(list(string), [])
    secondary_records = optional(list(string), [])
    primary_alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
    secondary_alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }))
    primary_health_check_key   = optional(string)
    secondary_health_check_key = optional(string)
  }))
  default = {}
}

### CloudWatch 알람 설정

variable "alarm_sns_topic_arns" {
  description = "헬스 체크 실패 알람 알림을 받을 SNS 토픽 ARN 목록 (us-east-1 리전의 토픽). prod에서는 반드시 설정 권장."
  type        = list(string)
  default     = []
}

### Route53 Resolver 설정

variable "enable_resolver" {
  description = "Route53 Resolver Outbound Endpoint 활성화 여부. 하이브리드 환경에서 활성화."
  type        = bool
  default     = false
}

variable "resolver_security_group_ids" {
  description = "Resolver Endpoint 보안 그룹 ID 목록"
  type        = list(string)
  default     = []
}

variable "resolver_subnet_ids" {
  description = "Resolver Endpoint 서브넷 ID 목록"
  type        = list(string)
  default     = []
}

variable "resolver_vpc_id" {
  description = "Resolver Rule 연결 VPC ID"
  type        = string
  default     = ""
}

variable "resolver_rules" {
  description = "DNS 포워딩 규칙 맵"
  type = map(object({
    domain_name = string
    target_ips = list(object({
      ip   = string
      port = optional(number, 53)
    }))
  }))
  default = {}
}

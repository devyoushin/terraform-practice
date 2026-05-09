### =============================================================================
### modules/route53/variables.tf
### Route53 모듈 입력 변수 정의
### =============================================================================

### -----------------------------------------------------------------------------
### 필수 변수
### -----------------------------------------------------------------------------

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용). 소문자, 숫자, 하이픈만 허용."
  type        = string
}

variable "environment" {
  description = "배포 환경. 리소스 명명 및 태그에 사용됩니다."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
  }
}

variable "zone_name" {
  description = "Route53 퍼블릭 호스팅 존 도메인 이름 (예: example.com, dev.example.com)."
  type        = string
}

variable "aws_region" {
  description = "AWS 리전. CloudWatch 헬스 체크 알람 설정에 사용됩니다."
  type        = string
  default     = "ap-northeast-2"
}

### -----------------------------------------------------------------------------
### 선택 변수 - 퍼블릭 호스팅 존
### -----------------------------------------------------------------------------

variable "create_zone" {
  description = "퍼블릭 호스팅 존 신규 생성 여부. true: 신규 생성, false: 기존 존 참조 (data source 사용)."
  type        = bool
  default     = true
}

variable "zone_comment" {
  description = "호스팅 존 설명. 빈 문자열이면 {project_name} {environment} 기반 자동 생성."
  type        = string
  default     = ""
}

### -----------------------------------------------------------------------------
### 선택 변수 - 프라이빗 호스팅 존
### -----------------------------------------------------------------------------

variable "enable_private_zone" {
  description = "프라이빗 호스팅 존 생성 여부. 하이브리드 DNS 또는 내부 서비스 디스커버리에 사용."
  type        = bool
  default     = false
}

variable "private_zone_name" {
  description = "프라이빗 호스팅 존 도메인 이름. 빈 문자열이면 internal.{zone_name} 형식으로 자동 생성."
  type        = string
  default     = ""
}

variable "private_zone_vpc_ids" {
  description = "프라이빗 호스팅 존과 연결할 VPC ID 목록. enable_private_zone = true 일 때 필수."
  type        = list(string)
  default     = []
}

### -----------------------------------------------------------------------------
### 선택 변수 - DNS 레코드
### -----------------------------------------------------------------------------

variable "records" {
  description = <<-EOT
    퍼블릭 존 DNS 레코드 맵.
    키: 레코드 식별자 (임의 문자열, Terraform 리소스 키로 사용).
    값:
      - name    : 레코드 이름 (예: "", "www", "api")
      - type    : 레코드 타입 (A, CNAME, MX, TXT, NS 등)
      - ttl     : TTL 초 단위 (alias 사용 시 무시됨, 기본값: 300)
      - records : 레코드값 목록 (alias 사용 시 무시됨)
      - alias   : AWS 리소스 별칭 설정 (ELB/CloudFront/S3 등 연결 시 사용)
        - name                   : 대상 AWS 리소스 DNS 이름
        - zone_id                : 대상 AWS 리소스의 호스팅 존 ID
        - evaluate_target_health : 대상 상태 확인 활성화 여부
  EOT
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

variable "private_records" {
  description = "프라이빗 존 DNS 레코드 맵. enable_private_zone = true 일 때만 유효. records 변수와 동일한 구조."
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

### -----------------------------------------------------------------------------
### 선택 변수 - 헬스 체크
### -----------------------------------------------------------------------------

variable "enable_health_checks" {
  description = "Route53 헬스 체크 생성 여부. staging/prod 환경에서 활성화 권장."
  type        = bool
  default     = false
}

variable "health_checks" {
  description = <<-EOT
    헬스 체크 설정 맵.
    키: 헬스 체크 식별자.
    값:
      - fqdn              : 체크할 도메인 이름 (예: api.example.com)
      - port              : 포트 (HTTP: 80, HTTPS: 443)
      - type              : 체크 타입 (HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP)
      - resource_path     : 체크 경로 (예: /health, /ping)
      - failure_threshold : 연속 실패 횟수 (기본: 3)
      - request_interval  : 체크 주기 초 (10 또는 30, 기본: 30)
      - regions           : 헬스 체크 리전 목록 (null이면 AWS 기본값 사용)
  EOT
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

### -----------------------------------------------------------------------------
### 선택 변수 - 페일오버 라우팅
### -----------------------------------------------------------------------------

variable "enable_failover_routing" {
  description = "페일오버 라우팅 정책 활성화 여부. prod 환경에서 고가용성을 위해 활성화 권장."
  type        = bool
  default     = false
}

variable "failover_records" {
  description = <<-EOT
    페일오버 라우팅 레코드 설정 맵.
    키: 레코드 식별자.
    값:
      - name                       : 레코드 이름
      - type                       : 레코드 타입 (A, CNAME 등)
      - ttl                        : TTL (alias 사용 시 무시됨)
      - primary_records            : Primary 레코드값 목록 (alias 사용 시 무시됨)
      - secondary_records          : Secondary 레코드값 목록 (alias 사용 시 무시됨)
      - primary_alias              : Primary alias 설정
      - secondary_alias            : Secondary alias 설정
      - primary_health_check_key   : health_checks 맵에서 Primary에 연결할 헬스 체크 키
      - secondary_health_check_key : health_checks 맵에서 Secondary에 연결할 헬스 체크 키
  EOT
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

### -----------------------------------------------------------------------------
### 선택 변수 - CloudWatch 알람 (헬스 체크 실패 알림)
### -----------------------------------------------------------------------------

variable "enable_health_check_alarms" {
  description = "헬스 체크 실패 CloudWatch 알람 활성화 여부. prod 환경에서 활성화 권장. us-east-1 리전에 알람이 생성됩니다."
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arns" {
  description = "CloudWatch 알람 발생 시 알림을 받을 SNS 토픽 ARN 목록. us-east-1 리전의 SNS 토픽이어야 합니다."
  type        = list(string)
  default     = []
}

### -----------------------------------------------------------------------------
### 선택 변수 - Route53 Resolver
### -----------------------------------------------------------------------------

variable "enable_resolver" {
  description = "Route53 Resolver Outbound Endpoint 생성 여부. 하이브리드 DNS(온프레미스 DNS 연동)에 사용."
  type        = bool
  default     = false
}

variable "resolver_security_group_ids" {
  description = "Route53 Resolver Endpoint에 적용할 보안 그룹 ID 목록. enable_resolver = true 일 때 필수."
  type        = list(string)
  default     = []
}

variable "resolver_subnet_ids" {
  description = "Route53 Resolver Endpoint를 배치할 서브넷 ID 목록 (최소 2개 AZ 권장). enable_resolver = true 일 때 필수."
  type        = list(string)
  default     = []
}

variable "resolver_vpc_id" {
  description = "Resolver Rule을 연결할 VPC ID. enable_resolver = true 일 때 필수."
  type        = string
  default     = ""
}

variable "resolver_rules" {
  description = <<-EOT
    DNS 포워딩 규칙 맵. 특정 도메인의 쿼리를 온프레미스 DNS 서버로 전달.
    키: 규칙 식별자.
    값:
      - domain_name : 포워딩할 도메인 (예: corp.example.com)
      - target_ips  : 온프레미스 DNS 서버 IP 및 포트 목록
        - ip   : DNS 서버 IP
        - port : DNS 포트 (기본: 53)
  EOT
  type = map(object({
    domain_name = string
    target_ips = list(object({
      ip   = string
      port = optional(number, 53)
    }))
  }))
  default = {}
}

### -----------------------------------------------------------------------------
### 선택 변수 - 태그
### -----------------------------------------------------------------------------

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

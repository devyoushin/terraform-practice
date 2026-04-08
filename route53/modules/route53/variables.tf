### ============================================================
### modules/route53/variables.tf
### Route53 모듈 입력 변수 정의
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

### 공통 태그

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### 호스팅 존 설정

variable "create_zone" {
  description = "새 호스팅 존 생성 여부 (true: 신규 생성 / false: 기존 존 참조)"
  type        = bool
  default     = true
}

variable "zone_name" {
  description = "호스팅 존 도메인 이름 (예: example.com, dev.example.com)"
  type        = string
}

variable "zone_comment" {
  description = "호스팅 존 설명 (미입력 시 project_name + environment 기반 자동 생성)"
  type        = string
  default     = ""
}

### DNS 레코드 설정

variable "records" {
  description = <<-EOT
    DNS 레코드 맵
    키: 레코드 식별자 (임의 문자열, Terraform 리소스 키로 사용)
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

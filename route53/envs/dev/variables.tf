### =============================================================================
### envs/dev/variables.tf
### 개발(dev) 환경 입력 변수 정의
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
  default     = "dev-team"
}

### 호스팅 존 설정

variable "zone_name" {
  description = "Route53 호스팅 존 도메인 이름 (dev 환경: 서브도메인 권장, 예: dev.example.com)"
  type        = string
}

### DNS 레코드 설정

variable "records" {
  description = "생성할 DNS 레코드 맵 (모듈 variables.tf 참고)"
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

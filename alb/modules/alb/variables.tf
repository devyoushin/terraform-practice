###
### ALB 모듈 - 변수 정의
### 필수 변수와 선택 변수(기본값 포함)로 구분
###

### ============================================================
### 필수 변수 (기본값 없음)
### ============================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 값은 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "vpc_id" {
  description = "ALB를 생성할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ALB를 배치할 서브넷 ID 목록 (퍼블릭 ALB의 경우 퍼블릭 서브넷 권장, 최소 2개)"
  type        = list(string)
}

### ============================================================
### ALB 기본 설정
### ============================================================

variable "internal" {
  description = "내부 ALB 여부 (true: 프라이빗, false: 퍼블릭)"
  type        = bool
  default     = false # 퍼블릭 ALB
}

variable "enable_deletion_protection" {
  description = "ALB 삭제 보호 활성화 여부 (prod 환경 권장)"
  type        = bool
  default     = false
}

### ============================================================
### 타겟 그룹 설정
### ============================================================

variable "target_type" {
  description = "타겟 그룹 타입 (instance / ip / lambda)"
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type 값은 instance, ip, lambda 중 하나여야 합니다."
  }
}

variable "health_check_path" {
  description = "헬스체크 경로"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "헬스체크 정상 응답 HTTP 상태 코드 (예: \"200\", \"200-299\")"
  type        = string
  default     = "200"
}

### ============================================================
### 리스너 및 HTTPS 설정
### 환경별 차이:
###   dev     - HTTP만 사용 (enable_https_redirect=false, create_https_listener=false)
###   staging - HTTP 기본 (필요 시 기존 인증서로 HTTPS 활성화 가능)
###   prod    - HTTPS 강제 (enable_https_redirect=true, create_https_listener=true)
### ============================================================

variable "enable_https_redirect" {
  description = "HTTP(80) → HTTPS(443) 301 리다이렉트 활성화 여부"
  type        = bool
  default     = true
}

variable "create_https_listener" {
  description = "HTTPS(443) 리스너 생성 여부"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "기존 ACM 인증서 ARN (null이면 create_acm_certificate로 생성된 인증서 사용)"
  type        = string
  default     = null
}

variable "create_acm_certificate" {
  description = "ACM 인증서 모듈 내 생성 여부 (true 시 domain_name 필수)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "ACM 인증서 발급 도메인 이름 (create_acm_certificate = true 일 때 필수)"
  type        = string
  default     = null
}

### ============================================================
### 액세스 로그 설정
### 환경별 차이:
###   dev / staging - 비활성화 (비용 절감)
###   prod          - 활성화 권장
### ============================================================

variable "enable_access_logs" {
  description = "ALB 액세스 로그 S3 저장 활성화 여부"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "ALB 액세스 로그를 저장할 S3 버킷 이름 (enable_access_logs = true 일 때 필수)"
  type        = string
  default     = null
}

### ============================================================
### 공통 태그
### ============================================================

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

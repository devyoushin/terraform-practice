###
### prod 환경 - 변수 정의
### dev/staging 변수에 acm_certificate_arn, access_logs_bucket 추가
###

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "owner" {
  description = "리소스 소유팀 또는 담당자"
  type        = string
  default     = "infra-team"
}

variable "vpc_id" {
  description = "ALB를 생성할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ALB를 배치할 퍼블릭 서브넷 ID 목록 (고가용성을 위해 최소 3개, 서로 다른 가용영역 권장)"
  type        = list(string)
}

variable "target_type" {
  description = "타겟 그룹 타입 (instance / ip / lambda)"
  type        = string
  default     = "instance"
}

variable "health_check_path" {
  description = "헬스체크 경로"
  type        = string
  default     = "/"
}

### ============================================================
### prod 환경 전용 변수
### ============================================================

variable "acm_certificate_arn" {
  description = "ACM 인증서 ARN (HTTPS 리스너에 사용, prod 환경 필수)"
  type        = string
}

variable "access_logs_bucket" {
  description = "ALB 액세스 로그를 저장할 S3 버킷 이름 (prod 환경 필수)"
  type        = string
}

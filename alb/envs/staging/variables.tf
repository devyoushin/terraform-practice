###
### staging 환경 - 변수 정의
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
  default     = "dev-team"
}

variable "vpc_id" {
  description = "ALB를 생성할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ALB를 배치할 퍼블릭 서브넷 ID 목록 (최소 2개, 서로 다른 가용영역)"
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

# HTTPS 활성화 시 아래 변수 주석 해제 후 사용
# variable "acm_certificate_arn" {
#   description = "기존 ACM 인증서 ARN (HTTPS 리스너 생성 시 필요)"
#   type        = string
#   default     = null
# }

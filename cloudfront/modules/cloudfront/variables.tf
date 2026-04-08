### =============================================================================
### modules/cloudfront/variables.tf
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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "s3_origin_bucket_domain" {
  description = "S3 오리진 버킷의 리전별 도메인 이름 (bucket_regional_domain_name). 비어있으면 S3 오리진 미사용."
  type        = string
  default     = ""
}

variable "alb_origin_domain" {
  description = "ALB 오리진 도메인 이름. 비어있으면 ALB 오리진 미사용. s3_origin_bucket_domain과 alb_origin_domain 중 하나는 반드시 설정해야 합니다."
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "루트 URL 요청 시 반환할 기본 객체. 정적 웹사이트의 경우 index.html."
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "CloudFront 배포에 연결할 커스텀 도메인 목록. ACM 인증서가 필요합니다."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "HTTPS 사용 시 ACM 인증서 ARN. 반드시 us-east-1 리전에서 발급된 인증서여야 합니다."
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront 엣지 로케이션 범위. PriceClass_All(전체), PriceClass_200(북미/유럽/아시아), PriceClass_100(북미/유럽만). 비용 vs 성능 트레이드오프."
  type        = string
  default     = "PriceClass_200"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class는 PriceClass_All, PriceClass_200, PriceClass_100 중 하나여야 합니다."
  }
}

variable "allowed_methods" {
  description = "허용 HTTP 메서드. 정적 파일 서빙: [GET, HEAD], API 프록시: [GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE]."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "web_acl_id" {
  description = "연결할 WAF Web ACL ID. 비어있으면 WAF 미연결."
  type        = string
  default     = ""
}

variable "access_log_bucket" {
  description = "액세스 로그 저장 S3 버킷 이름. 비어있으면 로깅 비활성화."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

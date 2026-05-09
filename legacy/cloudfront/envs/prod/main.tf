### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 CloudFront 배포 구성
###
### [환경 특성]
### - 커스텀 도메인 + ACM 인증서 : HTTPS 필수 (acm_certificate_arn은 us-east-1에서 발급)
### - PriceClass_200 : 아시아 엣지 로케이션 포함으로 한국 사용자 응답 속도 향상
### - 액세스 로그 활성화 : 트래픽 분석 및 보안 감사
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "prod"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "infra-team" }
}

module "cdn" {
  source = "../../modules/cloudfront"

  project_name            = var.project_name
  environment             = "prod"
  s3_origin_bucket_domain = var.s3_origin_bucket_domain
  price_class             = "PriceClass_200"
  aliases                 = var.aliases
  acm_certificate_arn     = var.acm_certificate_arn
  access_log_bucket       = var.access_log_bucket
  allowed_methods         = ["GET", "HEAD"]

  common_tags = local.common_tags
}

### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 CloudFront 배포 구성
###
### [환경 특성]
### - S3 오리진 사용 : 정적 웹사이트 파일 서빙
### - 커스텀 도메인 없음 : CloudFront 기본 도메인 사용 (비용 절감)
### - PriceClass_100 : 북미/유럽 엣지만 사용 (비용 절감)
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "dev"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

module "cdn" {
  source = "../../modules/cloudfront"

  project_name            = var.project_name
  environment             = "dev"
  s3_origin_bucket_domain = var.s3_origin_bucket_domain
  price_class             = "PriceClass_100"
  aliases                 = []
  acm_certificate_arn     = ""
  allowed_methods         = ["GET", "HEAD"]

  common_tags = local.common_tags
}

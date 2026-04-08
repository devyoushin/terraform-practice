### envs/staging/main.tf - CloudFront 스테이징 환경

terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws"; version = "~> 5.0" } }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner } }
}

locals {
  common_tags = { Project = var.project_name; Environment = "staging"; ManagedBy = "terraform"; Owner = var.owner; CostCenter = "dev-team" }
}

module "cdn" {
  source                  = "../../modules/cloudfront"
  project_name            = var.project_name
  environment             = "staging"
  s3_origin_bucket_domain = var.s3_origin_bucket_domain
  price_class             = "PriceClass_100"
  allowed_methods         = ["GET", "HEAD"]
  common_tags             = local.common_tags
}

### ============================================================
### envs/dev/main.tf
### 개발 환경 Route53 배포 설정
### 특징: 서브도메인(dev.example.com) 호스팅 존 신규 생성, 개발용 레코드
### ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

### AWS 프로바이더 설정 - 기본 태그로 모든 리소스에 공통 태그 자동 적용
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

### 공통 태그 로컬 변수
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-04-08"
  }
}

### Route53 모듈 호출
### dev 환경 특성:
###   - create_zone = true: dev 서브도메인 호스팅 존 신규 생성
###   - zone_name: dev.example.com (서브도메인)
###   - 개발용 레코드: A 레코드(루트), CNAME(www), TXT(SPF) 등
module "route53" {
  source = "../../modules/route53"

  ### 기본 정보
  project_name = var.project_name
  environment  = "dev"

  ### 호스팅 존 설정 - dev 서브도메인 신규 생성
  create_zone  = true
  zone_name    = var.zone_name
  zone_comment = "${var.project_name} 개발 환경 호스팅 존"

  ### DNS 레코드 설정
  records = var.records

  ### 공통 태그
  common_tags = local.common_tags
}

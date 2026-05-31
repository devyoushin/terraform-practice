### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 Route53 배포 설정
###
### [환경 특성]
### - create_zone = true: dev 서브도메인 호스팅 존 신규 생성
### - 헬스 체크 비활성화: 개발 환경 비용 절감 및 노이즈 방지
### - 페일오버 라우팅 비활성화: 단일 엔드포인트로 단순하게 운영
### - 기본 A/CNAME 레코드만 생성
### =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

### AWS 프로바이더 - 기본 리전
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

### AWS 프로바이더 - us-east-1 (Route53 헬스 체크 CloudWatch 알람용)
### 헬스 체크 비활성화 환경에서도 provider 블록은 선언 필요
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

### -----------------------------------------------------------------------------
### 공통 태그 로컬 변수
### -----------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

### -----------------------------------------------------------------------------
### Route53 모듈
### dev 환경 특성:
###   - create_zone = true: dev 서브도메인 신규 생성 (예: dev.example.com)
###   - 헬스 체크 비활성화: 비용 절감
###   - 페일오버 비활성화: 단순 구성
###   - 기본 레코드만 생성 (A 레코드, CNAME)
### -----------------------------------------------------------------------------
module "route53" {
  source = "../../modules/route53"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  ### 기본 정보
  project_name = var.project_name
  environment  = "dev"
  aws_region   = var.aws_region

  ### 퍼블릭 호스팅 존 설정 - dev 서브도메인 신규 생성
  create_zone  = true
  zone_name    = var.zone_name
  zone_comment = "${var.project_name} 개발 환경 호스팅 존"

  ### 프라이빗 존: dev 환경 불필요
  enable_private_zone = false

  ### DNS 레코드
  records = var.records

  ### 헬스 체크: dev 환경 비활성화
  enable_health_checks = false

  ### 페일오버: dev 환경 비활성화
  enable_failover_routing = false

  ### CloudWatch 알람: dev 환경 비활성화
  enable_health_check_alarms = false

  ### Resolver: dev 환경 비활성화
  enable_resolver = false

  ### 공통 태그
  common_tags = local.common_tags
}

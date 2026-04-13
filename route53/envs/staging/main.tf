### =============================================================================
### envs/staging/main.tf
### 스테이징(staging) 환경 Route53 배포 설정
###
### [환경 특성]
### - create_zone = true: staging 서브도메인 호스팅 존 신규 생성
### - 헬스 체크 활성화: HTTPS 엔드포인트 상태 모니터링
### - CloudWatch 알람 활성화: 헬스 체크 실패 알림 (us-east-1)
### - 페일오버 라우팅 비활성화: staging은 단일 엔드포인트
### - A 레코드, CNAME, ALB alias 레코드 포함
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

### AWS 프로바이더 - 기본 리전 (ap-northeast-2)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

### AWS 프로바이더 - us-east-1 (Route53 헬스 체크 CloudWatch 알람용)
### Route53 헬스 체크 메트릭은 글로벌 서비스이므로 반드시 us-east-1에서 알람 생성
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
    Environment = "staging"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### Route53 모듈
### staging 환경 특성:
###   - 헬스 체크 활성화: API, 웹 엔드포인트 상태 모니터링
###   - CloudWatch 알람: 헬스 체크 실패 즉시 알림
###   - 다양한 레코드 타입 검증 (A, CNAME, alias)
### -----------------------------------------------------------------------------
module "route53" {
  source = "../../modules/route53"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  ### 기본 정보
  project_name = var.project_name
  environment  = "staging"
  aws_region   = var.aws_region

  ### 퍼블릭 호스팅 존 설정
  create_zone  = true
  zone_name    = var.zone_name
  zone_comment = "${var.project_name} 스테이징 환경 호스팅 존"

  ### 프라이빗 존: staging 환경 선택적
  enable_private_zone  = var.enable_private_zone
  private_zone_name    = var.private_zone_name
  private_zone_vpc_ids = var.private_zone_vpc_ids

  ### DNS 레코드
  records         = var.records
  private_records = var.private_records

  ### 헬스 체크: staging 환경 활성화 (prod 동작 사전 검증)
  enable_health_checks = var.enable_health_checks
  health_checks        = var.health_checks

  ### 페일오버: staging 환경 비활성화 (단일 엔드포인트)
  enable_failover_routing = false

  ### CloudWatch 알람: 헬스 체크 활성화 시 함께 활성화
  enable_health_check_alarms = var.enable_health_checks
  alarm_sns_topic_arns       = var.alarm_sns_topic_arns

  ### Resolver: staging 환경 선택적
  enable_resolver             = var.enable_resolver
  resolver_security_group_ids = var.resolver_security_group_ids
  resolver_subnet_ids         = var.resolver_subnet_ids
  resolver_vpc_id             = var.resolver_vpc_id
  resolver_rules              = var.resolver_rules

  ### 공통 태그
  common_tags = local.common_tags
}

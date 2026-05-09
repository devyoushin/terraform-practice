### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 Route53 배포 설정
###
### [환경 특성]
### - create_zone = true: prod 루트 도메인 호스팅 존 신규 생성
### - 헬스 체크 활성화: HTTPS 엔드포인트 다중 체크 (API, 웹, 관리자)
### - 페일오버 라우팅 활성화: Primary/Secondary ALB 간 자동 전환
### - CloudWatch 알람 활성화: 헬스 체크 실패 즉시 알림 (us-east-1)
### - 프라이빗 존: 선택적 활성화 (내부 서비스 디스커버리)
### - 다양한 레코드 타입: ALB alias, CloudFront alias, CNAME, TXT
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
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### Route53 모듈
### prod 환경 특성:
###   - 헬스 체크 + CloudWatch 알람 필수 (장애 즉시 감지)
###   - 페일오버 라우팅 활성화 (고가용성)
###   - 다양한 레코드 타입 지원 (ALB alias, CloudFront alias, CNAME, TXT)
###   - Resolver 선택적 활성화 (하이브리드 환경)
### -----------------------------------------------------------------------------
module "route53" {
  source = "../../modules/route53"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  ### 기본 정보
  project_name = var.project_name
  environment  = "prod"
  aws_region   = var.aws_region

  ### 퍼블릭 호스팅 존 설정 - prod 루트 도메인
  create_zone  = var.create_zone
  zone_name    = var.zone_name
  zone_comment = "${var.project_name} 운영 환경 호스팅 존"

  ### 프라이빗 존: prod 환경 선택적 활성화
  enable_private_zone  = var.enable_private_zone
  private_zone_name    = var.private_zone_name
  private_zone_vpc_ids = var.private_zone_vpc_ids

  ### DNS 레코드
  records         = var.records
  private_records = var.private_records

  ### 헬스 체크: prod 환경 필수 활성화
  enable_health_checks = true
  health_checks        = var.health_checks

  ### 페일오버 라우팅: prod 환경 활성화 (고가용성)
  enable_failover_routing = var.enable_failover_routing
  failover_records        = var.failover_records

  ### CloudWatch 알람: prod 환경 필수 활성화
  enable_health_check_alarms = true
  alarm_sns_topic_arns       = var.alarm_sns_topic_arns

  ### Resolver: 하이브리드 환경 구성 시 활성화
  enable_resolver             = var.enable_resolver
  resolver_security_group_ids = var.resolver_security_group_ids
  resolver_subnet_ids         = var.resolver_subnet_ids
  resolver_vpc_id             = var.resolver_vpc_id
  resolver_rules              = var.resolver_rules

  ### 공통 태그
  common_tags = local.common_tags
}

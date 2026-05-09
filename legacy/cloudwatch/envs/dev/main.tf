### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 CloudWatch 구성
###
### [환경 특성]
### - 로그 보존 기간 짧게 설정 (비용 절감)
### - 알람 알림 비활성화 (개발 중 알람 피로 방지)
### - 대시보드 생성 안 함 (비용 절감)
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

module "monitoring" {
  source = "../../modules/cloudwatch"

  project_name = var.project_name
  environment  = "dev"

  # dev 환경: 알람 알림 비활성화 (알람 피로 방지)
  enable_alarm_notification = false
  enable_dashboard          = false

  # dev 환경: 7일 보관 (비용 절감)
  log_groups = [
    { name = "application", retention_days = 7 },
    { name = "nginx", retention_days = 7 },
    { name = "api", retention_days = 7 },
  ]

  # 기본 CPU 알람 (알림 없이 상태 추적용)
  metric_alarms = [
    {
      alarm_name          = "high-cpu"
      description         = "EC2 CPU 사용률 80% 초과"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "missing"
    }
  ]

  common_tags = local.common_tags
}

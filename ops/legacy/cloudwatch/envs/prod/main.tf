### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 CloudWatch 구성
###
### [환경 특성]
### - 알람 알림 활성화 : SNS → 이메일로 실시간 알림 (alarm_email 필수)
### - 로그 보존 기간 : 90일 (규정 준수)
### - 대시보드 활성화 : 인프라 현황 한눈에 파악
### - 다양한 메트릭 알람 : CPU, RDS 커넥션, ALB 5xx 에러
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

module "monitoring" {
  source = "../../modules/cloudwatch"

  project_name = var.project_name
  environment  = "prod"

  # prod 환경: 실시간 알람 알림 활성화
  enable_alarm_notification = true
  alarm_email               = var.alarm_email
  enable_dashboard          = true

  # prod 환경: 90일 보관 (규정 준수)
  log_groups = [
    { name = "application", retention_days = 90 },
    { name = "nginx", retention_days = 90 },
    { name = "api", retention_days = 90 },
  ]

  metric_alarms = [
    {
      alarm_name          = "high-cpu"
      description         = "EC2 CPU 사용률 80% 초과 (2회 연속)"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      treat_missing_data  = "missing"
    },
    {
      alarm_name          = "high-rds-connections"
      description         = "RDS 커넥션 수 100 초과"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "DatabaseConnections"
      namespace           = "AWS/RDS"
      period              = 300
      statistic           = "Average"
      threshold           = 100
      treat_missing_data  = "missing"
    },
    {
      alarm_name          = "alb-5xx-errors"
      description         = "ALB 5xx 에러 10건 초과"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      metric_name         = "HTTPCode_ELB_5XX_Count"
      namespace           = "AWS/ApplicationELB"
      period              = 60
      statistic           = "Sum"
      threshold           = 10
      treat_missing_data  = "notBreaching"
    }
  ]

  common_tags = local.common_tags
}

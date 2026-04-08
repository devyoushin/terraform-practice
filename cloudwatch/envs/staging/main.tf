### envs/staging/main.tf - 스테이징 환경 CloudWatch

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

module "monitoring" {
  source = "../../modules/cloudwatch"

  project_name              = var.project_name
  environment               = "staging"
  enable_alarm_notification = false
  enable_dashboard          = false

  log_groups = [
    { name = "application", retention_days = 14 },
    { name = "nginx", retention_days = 14 },
    { name = "api", retention_days = 14 },
  ]

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

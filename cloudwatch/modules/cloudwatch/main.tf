### =============================================================================
### modules/cloudwatch/main.tf
### AWS CloudWatch 로그 그룹, 메트릭 알람, 대시보드를 생성하는 모듈
### =============================================================================

locals {
  tags        = merge(var.common_tags, { Module = "cloudwatch", Environment = var.environment })
  name_prefix = "${var.project_name}-${var.environment}"
}

### -----------------------------------------------------------------------------
### 1. SNS 토픽 (알람 알림용)
### enable_alarm_notification = true 일 때만 생성
### -----------------------------------------------------------------------------
resource "aws_sns_topic" "alarm_topic" {
  count = var.enable_alarm_notification ? 1 : 0

  name = "${local.name_prefix}-alarm-topic"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = var.enable_alarm_notification && var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarm_topic[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

### -----------------------------------------------------------------------------
### 2. CloudWatch 로그 그룹들
### 애플리케이션 로그, 시스템 로그 등 용도별 로그 그룹 생성
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = { for lg in var.log_groups : lg.name => lg }

  name              = "/${local.name_prefix}/${each.key}"
  retention_in_days = each.value.retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 3. CloudWatch 메트릭 알람들
### CPU, 메모리, 에러율 등 서비스 지표 기반 알람
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = { for alarm in var.metric_alarms : alarm.alarm_name => alarm }

  alarm_name        = "${local.name_prefix}-${each.key}"
  alarm_description = each.value.description

  # 알람 조건
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data

  # 차원 (특정 리소스 지정)
  dimensions = each.value.dimensions

  # 알람/복구 시 SNS 알림 (enable_alarm_notification = true인 경우에만)
  alarm_actions = var.enable_alarm_notification ? [aws_sns_topic.alarm_topic[0].arn] : []
  ok_actions    = var.enable_alarm_notification ? [aws_sns_topic.alarm_topic[0].arn] : []

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 4. CloudWatch 대시보드 (enable_dashboard = true 일 때만 생성)
### EC2, RDS, ALB 핵심 메트릭을 한 화면에서 모니터링
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "this" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU 사용률"
          metrics = [["AWS/EC2", "CPUUtilization"]]
          period  = 300
          stat    = "Average"
          region  = "ap-northeast-2"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "RDS 데이터베이스 커넥션 수"
          metrics = [["AWS/RDS", "DatabaseConnections"]]
          period  = 300
          stat    = "Average"
          region  = "ap-northeast-2"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB 요청 수"
          metrics = [["AWS/ApplicationELB", "RequestCount"]]
          period  = 300
          stat    = "Sum"
          region  = "ap-northeast-2"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB 5xx 에러 수"
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count"]]
          period  = 300
          stat    = "Sum"
          region  = "ap-northeast-2"
          view    = "timeSeries"
        }
      }
    ]
  })
}

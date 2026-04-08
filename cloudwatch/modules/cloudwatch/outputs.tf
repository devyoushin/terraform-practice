output "alarm_topic_arn" {
  description = "CloudWatch 알람 SNS 토픽 ARN. enable_alarm_notification = false이면 null."
  value       = length(aws_sns_topic.alarm_topic) > 0 ? aws_sns_topic.alarm_topic[0].arn : null
}

output "log_group_names" {
  description = "생성된 CloudWatch 로그 그룹 이름 목록."
  value       = [for lg in aws_cloudwatch_log_group.log_groups : lg.name]
}

output "log_group_arns" {
  description = "생성된 CloudWatch 로그 그룹 ARN 목록."
  value       = [for lg in aws_cloudwatch_log_group.log_groups : lg.arn]
}

output "dashboard_arn" {
  description = "CloudWatch 대시보드 ARN. enable_dashboard = false이면 null."
  value       = length(aws_cloudwatch_dashboard.this) > 0 ? aws_cloudwatch_dashboard.this[0].dashboard_arn : null
}

output "alarm_topic_arn" { value = module.monitoring.alarm_topic_arn; description = "알람 SNS 토픽 ARN" }
output "log_group_names" { value = module.monitoring.log_group_names; description = "로그 그룹 이름 목록" }
output "dashboard_arn" { value = module.monitoring.dashboard_arn; description = "CloudWatch 대시보드 ARN" }

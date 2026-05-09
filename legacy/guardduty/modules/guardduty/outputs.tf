### ============================================================
### modules/guardduty/outputs.tf
### GuardDuty 모듈 출력값 정의
### ============================================================

### GuardDuty 탐지기 정보

output "guardduty_detector_id" {
  description = "GuardDuty 탐지기 ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}

output "guardduty_detector_arn" {
  description = "GuardDuty 탐지기 ARN"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].arn : null
}

### SNS 알림 정보

output "sns_topic_arn" {
  description = "GuardDuty 위협 알림용 SNS 토픽 ARN"
  value       = aws_sns_topic.guardduty_findings.arn
}

output "sns_topic_name" {
  description = "GuardDuty 위협 알림용 SNS 토픽 이름"
  value       = aws_sns_topic.guardduty_findings.name
}

### CloudWatch Events 정보

output "cloudwatch_event_rule_arn" {
  description = "GuardDuty Findings 감지용 CloudWatch Event Rule ARN"
  value       = aws_cloudwatch_event_rule.guardduty_findings.arn
}

output "cloudwatch_event_rule_name" {
  description = "GuardDuty Findings 감지용 CloudWatch Event Rule 이름"
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}

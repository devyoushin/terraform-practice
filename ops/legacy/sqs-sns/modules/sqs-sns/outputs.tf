### =============================================================================
### modules/sqs-sns/outputs.tf
### SQS-SNS 모듈 출력값 정의
### =============================================================================

### -----------------------------------------------------------------------------
### SNS 토픽 출력값
### -----------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "SNS 토픽 ARN. 다른 서비스에서 메시지를 게시(Publish)할 때 사용합니다."
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "SNS 토픽 이름."
  value       = aws_sns_topic.this.name
}

output "sns_topic_id" {
  description = "SNS 토픽 ID (ARN과 동일)."
  value       = aws_sns_topic.this.id
}

### -----------------------------------------------------------------------------
### 메인 SQS 큐 출력값
### -----------------------------------------------------------------------------

output "main_queue_id" {
  description = "메인 SQS 큐 URL. 메시지 송수신 시 사용합니다."
  value       = aws_sqs_queue.main.id
}

output "main_queue_arn" {
  description = "메인 SQS 큐 ARN. IAM 정책 및 SNS 구독 설정 시 사용합니다."
  value       = aws_sqs_queue.main.arn
}

output "main_queue_name" {
  description = "메인 SQS 큐 이름."
  value       = aws_sqs_queue.main.name
}

output "main_queue_url" {
  description = "메인 SQS 큐 URL (main_queue_id와 동일). SDK에서 큐에 접근할 때 사용합니다."
  value       = aws_sqs_queue.main.url
}

### -----------------------------------------------------------------------------
### DLQ 출력값
### -----------------------------------------------------------------------------

output "dlq_id" {
  description = "Dead Letter Queue URL."
  value       = aws_sqs_queue.dlq.id
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN."
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_name" {
  description = "Dead Letter Queue 이름."
  value       = aws_sqs_queue.dlq.name
}

### -----------------------------------------------------------------------------
### FIFO 큐 출력값 (enable_fifo_queue = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "fifo_queue_id" {
  description = "FIFO SQS 큐 URL. enable_fifo_queue = true 일 때만 값이 존재합니다."
  value       = var.enable_fifo_queue && !var.fifo_queue ? aws_sqs_queue.fifo[0].id : null
}

output "fifo_queue_arn" {
  description = "FIFO SQS 큐 ARN. enable_fifo_queue = true 일 때만 값이 존재합니다."
  value       = var.enable_fifo_queue && !var.fifo_queue ? aws_sqs_queue.fifo[0].arn : null
}

output "fifo_dlq_arn" {
  description = "FIFO DLQ ARN. enable_fifo_queue = true 일 때만 값이 존재합니다."
  value       = var.enable_fifo_queue && !var.fifo_queue ? aws_sqs_queue.fifo_dlq[0].arn : null
}

### -----------------------------------------------------------------------------
### CloudWatch 알람 출력값 (enable_cloudwatch_alarms = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "queue_depth_alarm_arn" {
  description = "메인 큐 깊이 CloudWatch 알람 ARN. enable_cloudwatch_alarms = true 일 때만 값이 존재합니다."
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.queue_depth[0].arn : null
}

output "dlq_depth_alarm_arn" {
  description = "DLQ 깊이 CloudWatch 알람 ARN. enable_cloudwatch_alarms = true 일 때만 값이 존재합니다."
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dlq_depth[0].arn : null
}

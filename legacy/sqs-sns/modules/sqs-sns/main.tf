### =============================================================================
### modules/sqs-sns/main.tf
### AWS SQS 큐 및 SNS 토픽을 생성하는 재사용 가능한 모듈
### =============================================================================

### -----------------------------------------------------------------------------
### 로컬 변수
### -----------------------------------------------------------------------------
locals {
  # 리소스 이름 접두사
  name_prefix = "${var.project_name}-${var.environment}"

  # FIFO 큐 이름 (접미사 .fifo 자동 추가)
  main_queue_name = var.fifo_queue ? "${local.name_prefix}-${var.queue_name}.fifo" : "${local.name_prefix}-${var.queue_name}"
  dlq_name        = var.fifo_queue ? "${local.name_prefix}-${var.queue_name}-dlq.fifo" : "${local.name_prefix}-${var.queue_name}-dlq"

  # FIFO 토픽 이름 (접미사 .fifo 자동 추가)
  topic_name = var.fifo_topic ? "${local.name_prefix}-${var.topic_name}.fifo" : "${local.name_prefix}-${var.topic_name}"

  # 공통 태그 병합
  tags = merge(var.common_tags, {
    Module      = "sqs-sns"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. DLQ (Dead Letter Queue) - 메인 큐와 FIFO 큐 공용
### 처리 실패한 메시지를 별도 큐에 보존하여 재처리 및 디버깅 용이
### -----------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  name = local.dlq_name

  # FIFO 큐 설정 (메인 큐와 동일하게 맞춤)
  fifo_queue = var.fifo_queue

  # DLQ는 메인 큐보다 긴 보존 기간 설정 (분석/재처리 시간 확보)
  message_retention_seconds = var.dlq_message_retention_seconds

  # KMS 암호화 (prod 권장)
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? 300 : null

  tags = merge(local.tags, {
    Name = local.dlq_name
    Type = "dlq"
  })
}

### -----------------------------------------------------------------------------
### 2. 메인 SQS 표준/FIFO 큐
### -----------------------------------------------------------------------------
resource "aws_sqs_queue" "main" {
  name = local.main_queue_name

  # 큐 타입 설정
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  # 메시지 설정
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # DLQ 연결 (redrive policy)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  # KMS 암호화 (prod 권장)
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? 300 : null

  tags = merge(local.tags, {
    Name = local.main_queue_name
    Type = "main"
  })
}

### -----------------------------------------------------------------------------
### 3. FIFO 전용 추가 큐 (enable_fifo_queue = true 일 때만 생성)
### 순서 보장이 필요한 워크로드(예: 주문 처리, 금융 트랜잭션)에 사용
### -----------------------------------------------------------------------------
resource "aws_sqs_queue" "fifo_dlq" {
  count = var.enable_fifo_queue && !var.fifo_queue ? 1 : 0

  name       = "${local.name_prefix}-${var.queue_name}-fifo-dlq.fifo"
  fifo_queue = true

  message_retention_seconds = var.dlq_message_retention_seconds

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? 300 : null

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-${var.queue_name}-fifo-dlq.fifo"
    Type = "fifo-dlq"
  })
}

resource "aws_sqs_queue" "fifo" {
  count = var.enable_fifo_queue && !var.fifo_queue ? 1 : 0

  name                        = "${local.name_prefix}-${var.queue_name}-fifo.fifo"
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = 0 # FIFO 큐는 delay_seconds = 0 강제
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fifo_dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  })

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? 300 : null

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-${var.queue_name}-fifo.fifo"
    Type = "fifo"
  })
}

### -----------------------------------------------------------------------------
### 4. SNS 토픽
### -----------------------------------------------------------------------------
resource "aws_sns_topic" "this" {
  name = local.topic_name

  # FIFO 토픽 설정
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  # KMS 암호화 (prod 권장)
  kms_master_key_id = var.kms_master_key_id != null ? var.kms_master_key_id : null

  # 전송 정책 (배달 재시도 횟수, 지연 등 설정)
  delivery_policy = var.sns_delivery_policy != "" ? var.sns_delivery_policy : null

  tags = merge(local.tags, {
    Name = local.topic_name
  })
}

### -----------------------------------------------------------------------------
### 5. SNS 구독 - 이메일
### -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_subscriptions)

  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}

### -----------------------------------------------------------------------------
### 6. SNS 구독 - SQS (메인 큐)
### SNS 메시지를 SQS 큐로 팬아웃 전달
### -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn

  # Raw message delivery: true이면 SNS 래퍼 없이 순수 메시지만 SQS에 전달
  raw_message_delivery = var.sqs_raw_message_delivery

  # 메시지 필터 정책 (지정된 경우에만 적용)
  filter_policy        = var.sns_filter_policy != "" ? var.sns_filter_policy : null
  filter_policy_scope  = var.sns_filter_policy != "" ? var.sns_filter_policy_scope : null
}

### -----------------------------------------------------------------------------
### 7. SNS 구독 - Lambda (선택적, lambda_subscription_arns 지정 시 생성)
### -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda" {
  for_each = toset(var.lambda_subscription_arns)

  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = each.value
}

### -----------------------------------------------------------------------------
### 8. SNS 구독 - HTTPS (선택적, https_subscription_urls 지정 시 생성)
### -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "https" {
  for_each = toset(var.https_subscription_urls)

  topic_arn            = aws_sns_topic.this.arn
  protocol             = "https"
  endpoint             = each.value
  raw_message_delivery = false
}

### -----------------------------------------------------------------------------
### 9. SQS 큐 정책 - SNS가 메인 큐에 메시지를 게시할 수 있도록 허용
### -----------------------------------------------------------------------------
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      },
      # 추가 허용 Principal (예: 다른 AWS 계정, 서비스)
      # 빈 목록이면 해당 Statement는 생성하지 않음
    ]
  })
}

### -----------------------------------------------------------------------------
### 10. SQS 큐 정책 - FIFO 큐 (enable_fifo_queue = true 일 때만 생성)
### -----------------------------------------------------------------------------
resource "aws_sqs_queue_policy" "fifo" {
  count = var.enable_fifo_queue && !var.fifo_queue ? 1 : 0

  queue_url = aws_sqs_queue.fifo[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.fifo[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.this.arn
          }
        }
      }
    ]
  })
}

### -----------------------------------------------------------------------------
### 11. CloudWatch 알람 - 메인 큐 깊이 (enable_cloudwatch_alarms = true 일 때만 생성)
### 큐에 처리되지 않은 메시지가 쌓이는 경우 알림 발송
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-${var.queue_name}-queue-depth"
  alarm_description   = "${local.main_queue_name} 큐 깊이가 임계값(${var.queue_depth_alarm_threshold})을 초과했습니다. 컨슈머 처리 속도를 확인하세요."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.queue_depth_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  # 알람 발생 시 SNS 토픽으로 알림 전송
  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-${var.queue_name}-queue-depth-alarm"
  })
}

### -----------------------------------------------------------------------------
### 12. CloudWatch 알람 - DLQ 깊이 (enable_cloudwatch_alarms = true 일 때만 생성)
### DLQ에 메시지가 쌓이면 처리 실패가 발생한 것이므로 즉시 알림 필요
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-${var.queue_name}-dlq-depth"
  alarm_description   = "${local.dlq_name} DLQ에 메시지가 감지되었습니다. 처리 실패 원인을 즉시 확인하세요."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 1 # DLQ에 메시지가 1개라도 쌓이면 즉시 알림
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-${var.queue_name}-dlq-depth-alarm"
  })
}

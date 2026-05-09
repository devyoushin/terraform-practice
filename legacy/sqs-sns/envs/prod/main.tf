### =============================================================================
### envs/prod/main.tf
### 운영(prod) 환경 SQS-SNS 구성
###
### [환경 특성]
### - KMS 암호화 필수: 고객 관리형 KMS 키로 모든 메시지 암호화
### - 메시지 보존 기간 14일: 장애 대응 및 재처리를 위한 충분한 보존 기간
### - 가시성 타임아웃 300초: 실제 워크로드 처리 시간을 고려한 설정
### - CloudWatch 알람 활성화: 큐 깊이 및 DLQ 실시간 모니터링
### - DLQ maxReceiveCount 5: 일시적 오류 재시도 후 DLQ로 이동
### - FIFO 큐 선택적 활성화: 순서 보장이 필요한 워크로드에 사용
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

### -----------------------------------------------------------------------------
### 공통 태그 정의
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
### 메인 SQS-SNS 모듈
### prod 특이사항: KMS 필수, 장기 보존, CloudWatch 알람, DLQ 강화
### -----------------------------------------------------------------------------
module "sqs_sns" {
  source = "../../modules/sqs-sns"

  project_name = var.project_name
  environment  = "prod"
  queue_name   = var.queue_name
  topic_name   = var.topic_name

  # prod 환경: 실제 워크로드 처리 시간을 고려한 가시성 타임아웃
  # Lambda 최대 실행 시간(15분) 또는 컨슈머 처리 시간에 맞게 조정 필요
  visibility_timeout_seconds = 300

  # prod 환경: 14일 보존 (장애 대응 및 재처리 시간 확보)
  message_retention_seconds = 1209600

  # Long Polling 활성화 (API 호출 비용 절감)
  receive_wait_time_seconds = 20

  # DLQ 설정: 5회 실패 후 DLQ로 이동 (일시적 오류 재시도 고려)
  max_receive_count             = 5
  dlq_message_retention_seconds = 1209600 # DLQ도 14일 보존

  # prod 환경: FIFO 큐 선택적 활성화 (terraform.tfvars에서 제어)
  enable_fifo_queue = var.enable_fifo_queue

  # prod 환경: KMS 암호화 필수 (고객 관리형 KMS 키)
  kms_master_key_id = var.kms_key_id

  # 이메일 구독
  email_subscriptions = var.email_subscriptions

  # Lambda 구독 (선택적)
  lambda_subscription_arns = var.lambda_subscription_arns

  # prod 환경: CloudWatch 알람 활성화 (즉각적인 이상 감지)
  enable_cloudwatch_alarms    = true
  queue_depth_alarm_threshold = var.queue_depth_alarm_threshold
  alarm_evaluation_periods    = 2
  alarm_sns_topic_arns        = var.alarm_sns_topic_arns

  # SNS raw message delivery
  sqs_raw_message_delivery = var.sqs_raw_message_delivery

  # SNS 메시지 필터 정책 (필요 시 설정)
  sns_filter_policy       = var.sns_filter_policy
  sns_filter_policy_scope = var.sns_filter_policy_scope

  common_tags = local.common_tags
}

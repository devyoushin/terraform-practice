### =============================================================================
### envs/staging/main.tf
### 스테이징(staging) 환경 SQS-SNS 구성
###
### [환경 특성]
### - KMS 암호화 선택적 적용: kms_key_id 변수로 제어 (prod 동작 사전 검증)
### - 메시지 보존 기간 7일: prod와 유사한 운영 환경 검증
### - 가시성 타임아웃 120초: 실제 처리 시간을 고려한 현실적 설정
### - CloudWatch 알람 활성화: 모니터링 체계 prod와 동일하게 검증
### - FIFO 큐 선택적 활성화: prod 배포 전 FIFO 동작 검증 가능
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
      Environment = "staging"
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
    Environment = "staging"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "infra-team"
  }
}

### -----------------------------------------------------------------------------
### 메인 SQS-SNS 모듈
### staging 특이사항: prod와 동일한 조건으로 검증, CloudWatch 알람 활성화
### -----------------------------------------------------------------------------
module "sqs_sns" {
  source = "../../modules/sqs-sns"

  project_name = var.project_name
  environment  = "staging"
  queue_name   = var.queue_name
  topic_name   = var.topic_name

  # staging 환경: 실제 처리 시간을 반영한 가시성 타임아웃
  visibility_timeout_seconds = 120

  # staging 환경: 7일 보존 (prod 동작 검증)
  message_retention_seconds = 604800

  # Long Polling 활성화
  receive_wait_time_seconds = 20

  # DLQ 설정: 안정적인 재처리를 위해 maxReceiveCount 5
  max_receive_count             = 5
  dlq_message_retention_seconds = 1209600 # 14일 (DLQ는 더 길게)

  # staging 환경: FIFO 큐 선택적 활성화 (terraform.tfvars에서 제어)
  enable_fifo_queue = var.enable_fifo_queue

  # staging 환경: 선택적 KMS 암호화 (prod 동작 검증용)
  kms_master_key_id = var.kms_key_id

  # 이메일 구독
  email_subscriptions = var.email_subscriptions

  # staging 환경: CloudWatch 알람 활성화 (모니터링 체계 검증)
  enable_cloudwatch_alarms    = true
  queue_depth_alarm_threshold = var.queue_depth_alarm_threshold
  alarm_evaluation_periods    = 2
  alarm_sns_topic_arns        = var.alarm_sns_topic_arns

  # SNS raw message delivery
  sqs_raw_message_delivery = false

  common_tags = local.common_tags
}

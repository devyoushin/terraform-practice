### =============================================================================
### envs/dev/main.tf
### 개발(dev) 환경 SQS-SNS 구성
###
### [환경 특성]
### - KMS 암호화 미사용: SSE-SQS 기본 암호화로 비용 절감
### - 메시지 보존 기간 4일: 짧은 개발 사이클에 적합
### - 가시성 타임아웃 30초: 빠른 테스트 반복을 위해 짧게 설정
### - CloudWatch 알람 비활성화: 개발 환경 노이즈 방지
### - DLQ maxReceiveCount 3: 개발 중 빠른 재처리 확인
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
      Environment = "dev"
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
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "dev-team"
  }
}

### -----------------------------------------------------------------------------
### 메인 SQS-SNS 모듈 (표준 큐 + SNS 토픽)
### 용도: 애플리케이션 이벤트 처리, 비동기 작업 큐
### dev 특이사항: KMS 없음, 짧은 보존 기간, 빠른 가시성 타임아웃
### -----------------------------------------------------------------------------
module "sqs_sns" {
  source = "../../modules/sqs-sns"

  project_name = var.project_name
  environment  = "dev"
  queue_name   = var.queue_name
  topic_name   = var.topic_name

  # dev 환경: 짧은 가시성 타임아웃 (빠른 테스트 반복)
  visibility_timeout_seconds = 30

  # dev 환경: 4일 보존 (짧은 개발 사이클)
  message_retention_seconds = 345600

  # Long Polling 활성화 (API 호출 비용 절감)
  receive_wait_time_seconds = 20

  # DLQ 설정: dev는 빠른 재처리 확인을 위해 낮은 maxReceiveCount
  max_receive_count             = 3
  dlq_message_retention_seconds = 345600

  # dev 환경: FIFO 큐 비활성화 (표준 큐만 사용)
  enable_fifo_queue = false

  # dev 환경: KMS 암호화 미사용 (SSE-SQS 기본 암호화)
  kms_master_key_id = null

  # dev 환경: 이메일 구독 (필요 시 terraform.tfvars에서 설정)
  email_subscriptions = var.email_subscriptions

  # dev 환경: CloudWatch 알람 비활성화
  enable_cloudwatch_alarms = false

  # SNS raw message delivery (SQS 구독)
  sqs_raw_message_delivery = false

  common_tags = local.common_tags
}

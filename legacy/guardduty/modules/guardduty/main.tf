### ============================================================
### modules/guardduty/main.tf
### AWS GuardDuty 위협 탐지 및 알림 리소스 정의
### ============================================================

### ---------------------------------------------------------------
### GuardDuty 탐지기 (Detector)
### 모든 GuardDuty 기능의 핵심 리소스
### ---------------------------------------------------------------
resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  ### 탐지기 활성화 여부
  enable = true

  ### 결과 발행 주기
  ### dev: SIX_HOURS (비용 최소화)
  ### staging: ONE_HOUR (중간 수준)
  ### prod: FIFTEEN_MINUTES (실시간에 가까운 탐지)
  finding_publishing_frequency = var.finding_publishing_frequency

  ### 데이터 소스 별 탐지 설정
  datasources {
    ### S3 로그 기반 위협 탐지 (S3 데이터 이벤트 모니터링)
    s3_logs {
      enable = var.enable_s3_logs
    }

    ### Kubernetes 감사 로그 위협 탐지 (EKS 환경)
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_audit_logs
      }
    }

    ### EC2 악성코드 탐지 (추가 비용 발생)
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-guardduty-detector"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### SNS 토픽 - GuardDuty 위협 인텔리전스 알림 채널
### ---------------------------------------------------------------
resource "aws_sns_topic" "guardduty_findings" {
  name = "${var.project_name}-${var.environment}-guardduty-findings"

  ### KMS 암호화 (보안 강화)
  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-guardduty-findings"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### SNS 토픽 정책 - GuardDuty 및 CloudWatch Events 발행 허용
### ---------------------------------------------------------------
resource "aws_sns_topic_policy" "guardduty_findings" {
  arn    = aws_sns_topic.guardduty_findings.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  ### SNS 기본 발행 권한 (토픽 소유자)
  statement {
    sid    = "AllowSNSDefaultActions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["SNS:*"]
    resources = [aws_sns_topic.guardduty_findings.arn]
  }

  ### CloudWatch Events (EventBridge) 발행 허용
  statement {
    sid    = "AllowCloudWatchEventsPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.guardduty_findings.arn]
  }
}

### ---------------------------------------------------------------
### SNS 이메일 구독 - alert_email 지정 시 자동 구독 생성
### ---------------------------------------------------------------
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.guardduty_findings.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

### ---------------------------------------------------------------
### CloudWatch Event Rule - GuardDuty Findings 이벤트 감지
### min_severity 이상의 심각도(severity)를 가진 findings만 트리거
### ---------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "GuardDuty 위협 탐지 결과 이벤트 룰 (심각도 ${var.min_severity} 이상)"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        ### severity 필드는 숫자이며, 조건식으로 최소값 이상을 필터링
        { numeric = [">=", var.min_severity] }
      ]
    }
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-guardduty-findings"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### CloudWatch Event Target - SNS 토픽으로 이벤트 전달
### ---------------------------------------------------------------
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindingsToSNS"
  arn       = aws_sns_topic.guardduty_findings.arn

  ### 이벤트 데이터를 가공하여 사람이 읽기 쉬운 형태로 전달
  input_transformer {
    input_paths = {
      account    = "$.account"
      region     = "$.region"
      severity   = "$.detail.severity"
      type       = "$.detail.type"
      title      = "$.detail.title"
      detectorId = "$.detail.detectorId"
      findingId  = "$.detail.id"
      updatedAt  = "$.detail.updatedAt"
      description = "$.detail.description"
    }

    input_template = <<-EOT
      {
        "알림 제목": "<title>",
        "심각도": "<severity>",
        "탐지 유형": "<type>",
        "설명": "<description>",
        "AWS 계정": "<account>",
        "리전": "<region>",
        "탐지기 ID": "<detectorId>",
        "결과 ID": "<findingId>",
        "업데이트 시각": "<updatedAt>"
      }
    EOT
  }
}

### ---------------------------------------------------------------
### GuardDuty 결과 필터 (선택 사항)
### enable_filter = true 시 활성화, 신뢰할 수 있는 소스 제외
### ---------------------------------------------------------------
resource "aws_guardduty_filter" "trusted_ips" {
  count = var.enable_guardduty && var.enable_filter ? 1 : 0

  name        = "${var.project_name}-${var.environment}-trusted-ips-filter"
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.this[0].id
  rank        = 1
  description = "신뢰할 수 있는 내부 IP에서 발생한 결과를 자동으로 보관 처리"

  finding_criteria {
    ### 신뢰 IP 목록에서 발생한 findings는 ARCHIVE 처리
    criterion {
      field  = "service.action.networkConnectionAction.remoteIpDetails.ipAddressV4"
      equals = length(var.filter_trusted_ips) > 0 ? var.filter_trusted_ips : ["127.0.0.1"]
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-trusted-ips-filter"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### 데이터 소스 - 현재 AWS 계정 정보 조회
### ---------------------------------------------------------------
data "aws_caller_identity" "current" {}

### =============================================================================
### modules/waf/main.tf
### AWS WAFv2 Web ACL을 생성하는 재사용 가능한 모듈
### REGIONAL: ALB, API Gateway에 연결
### CLOUDFRONT: CloudFront 배포에 연결 (us-east-1 리전에서 생성 필요)
### =============================================================================

locals {
  tags        = merge(var.common_tags, { Module = "waf", Environment = var.environment })
  name_prefix = "${var.project_name}-${var.environment}"
}

### -----------------------------------------------------------------------------
### 1. IP 차단 목록 (blocked_ip_addresses가 있을 때만 생성)
### -----------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "blocked_ips" {
  count = length(var.blocked_ip_addresses) > 0 ? 1 : 0

  name               = "${local.name_prefix}-blocked-ips"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. IP 허용 목록 (allowed_ip_addresses가 있을 때만 생성)
### 화이트리스트 방식: default_action = "block"과 함께 사용
### -----------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "allowed_ips" {
  count = length(var.allowed_ip_addresses) > 0 ? 1 : 0

  name               = "${local.name_prefix}-allowed-ips"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 3. WAF Web ACL
### -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = "${local.name_prefix}-web-acl"
  scope       = var.scope
  description = "${var.environment} 환경 WAF Web ACL"

  # 기본 동작: 규칙에 매치되지 않는 요청에 대한 처리
  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-web-acl"
    sampled_requests_enabled   = true
  }

  ### AWS 관리형 규칙 1: 공통 취약점 차단 (OWASP Top 10 등)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      dynamic "none" {
        for_each = var.managed_rules_action == "none" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.managed_rules_action == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  ### AWS 관리형 규칙 2: 알려진 악성 입력 차단
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      dynamic "none" {
        for_each = var.managed_rules_action == "none" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = var.managed_rules_action == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  ### Rate Limiting 규칙 (선택적)
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 3

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  ### IP 차단 규칙 (blocked_ips IP Set이 있을 때)
  dynamic "rule" {
    for_each = length(var.blocked_ip_addresses) > 0 ? [1] : []
    content {
      name     = "BlockedIPsRule"
      priority = 4

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-blocked-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  ### IP 허용 규칙 (allowed_ips IP Set이 있을 때)
  dynamic "rule" {
    for_each = length(var.allowed_ip_addresses) > 0 ? [1] : []
    content {
      name     = "AllowedIPsRule"
      priority = 5

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowed_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.name_prefix}-allowed-ips"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 4. WAF와 ALB/API Gateway 연결 (resource_arn이 있을 때만)
### CloudFront 연결은 aws_cloudfront_distribution의 web_acl_id로 직접 설정
### -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {
  count = var.resource_arn != "" ? 1 : 0

  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

### -----------------------------------------------------------------------------
### 5. WAF 로깅 설정 (log_destination_arn이 있을 때만)
### -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.log_destination_arn != "" ? 1 : 0

  log_destination_configs = [var.log_destination_arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}

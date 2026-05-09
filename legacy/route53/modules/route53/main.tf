### =============================================================================
### modules/route53/main.tf
### AWS Route53 호스팅 존, DNS 레코드, 헬스 체크, 페일오버 라우팅 정의
### =============================================================================

### -----------------------------------------------------------------------------
### Provider 설정
### us_east_1 alias: CloudWatch 헬스 체크 알람은 반드시 us-east-1에 생성
### Route53 헬스 체크 메트릭(AWS/Route53)은 글로벌 서비스로 us-east-1에서만 접근 가능
### -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

### -----------------------------------------------------------------------------
### 로컬 변수
### -----------------------------------------------------------------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # 퍼블릭 존 ID (새 생성 또는 기존 참조 중 하나 선택)
  public_zone_id = var.create_zone ? aws_route53_zone.public[0].zone_id : data.aws_route53_zone.public[0].zone_id

  # 공통 태그 병합
  tags = merge(var.common_tags, {
    Module      = "route53"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. 퍼블릭 호스팅 존 생성 (create_zone = true 일 때만 생성)
### -----------------------------------------------------------------------------
resource "aws_route53_zone" "public" {
  count = var.create_zone ? 1 : 0

  name    = var.zone_name
  comment = var.zone_comment != "" ? var.zone_comment : "${var.project_name} ${var.environment} 퍼블릭 호스팅 존"

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-zone"
    Type = "public"
  })
}

### -----------------------------------------------------------------------------
### 2. 기존 퍼블릭 호스팅 존 참조 (create_zone = false 일 때 데이터 소스 사용)
### -----------------------------------------------------------------------------
data "aws_route53_zone" "public" {
  count = var.create_zone ? 0 : 1

  name         = var.zone_name
  private_zone = false
}

### -----------------------------------------------------------------------------
### 3. 프라이빗 호스팅 존 (enable_private_zone = true 일 때만 생성)
### 하이브리드 DNS, 내부 서비스 디스커버리에 사용
### -----------------------------------------------------------------------------
resource "aws_route53_zone" "private" {
  count = var.enable_private_zone ? 1 : 0

  name    = var.private_zone_name != "" ? var.private_zone_name : "internal.${var.zone_name}"
  comment = "${var.project_name} ${var.environment} 프라이빗 호스팅 존 (내부 서비스용)"

  # VPC와 연결 (프라이빗 존은 반드시 VPC 지정 필요)
  dynamic "vpc" {
    for_each = var.private_zone_vpc_ids

    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-private-zone"
    Type = "private"
  })
}

### -----------------------------------------------------------------------------
### 4. 일반 DNS 레코드 (A, CNAME, MX, TXT, NS 등)
### alias 블록 동적 추가 지원 (ALB, CloudFront, S3 등 AWS 리소스 연결)
### -----------------------------------------------------------------------------
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.public_zone_id
  name    = each.value.name
  type    = each.value.type

  # alias 블록 - alias 설정이 있을 때만 추가 (ELB/CloudFront/S3 등 AWS 리소스 연결용)
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # ttl - alias 사용 시 생략 (alias와 ttl/records는 동시 사용 불가)
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null
}

### -----------------------------------------------------------------------------
### 5. 프라이빗 존 DNS 레코드
### -----------------------------------------------------------------------------
resource "aws_route53_record" "private" {
  for_each = var.enable_private_zone ? var.private_records : {}

  zone_id = aws_route53_zone.private[0].zone_id
  name    = each.value.name
  type    = each.value.type

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null
}

### -----------------------------------------------------------------------------
### 6. 헬스 체크 (enable_health_checks = true 일 때만 생성)
### HTTP/HTTPS 엔드포인트 상태를 주기적으로 확인
### staging/prod 환경에서 활성화 권장
### -----------------------------------------------------------------------------
resource "aws_route53_health_check" "this" {
  for_each = var.enable_health_checks ? var.health_checks : {}

  fqdn              = each.value.fqdn
  port              = each.value.port
  type              = each.value.type
  resource_path     = each.value.resource_path
  failure_threshold = each.value.failure_threshold
  request_interval  = each.value.request_interval

  # HTTPS 헬스 체크 시 SNI 활성화
  enable_sni = each.value.type == "HTTPS" || each.value.type == "HTTPS_STR_MATCH" ? true : false

  # 헬스 체크 리전 (글로벌 분산 체크를 위해 여러 리전 사용)
  regions = each.value.regions != null ? each.value.regions : null

  # CloudWatch 알람 연동 (enable_health_check_alarms = true 시)
  cloudwatch_alarm_name   = var.enable_health_check_alarms ? "${local.name_prefix}-health-${each.key}" : null
  cloudwatch_alarm_region = var.enable_health_check_alarms ? var.aws_region : null
  insufficient_data_health_status = var.enable_health_check_alarms ? "Unhealthy" : null

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-health-${each.key}"
  })
}

### -----------------------------------------------------------------------------
### 7. 페일오버 라우팅 - Primary 레코드
### (enable_failover_routing = true 일 때만 생성)
### Primary 엔드포인트 장애 시 Secondary로 자동 전환
### -----------------------------------------------------------------------------
resource "aws_route53_record" "failover_primary" {
  for_each = var.enable_failover_routing ? var.failover_records : {}

  zone_id = local.public_zone_id
  name    = each.value.name
  type    = each.value.type

  # 페일오버 라우팅 정책
  set_identifier = "${each.key}-primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  # Primary 헬스 체크 연결
  health_check_id = each.value.primary_health_check_key != null ? aws_route53_health_check.this[each.value.primary_health_check_key].id : null

  dynamic "alias" {
    for_each = each.value.primary_alias != null ? [each.value.primary_alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  ttl     = each.value.primary_alias == null ? each.value.ttl : null
  records = each.value.primary_alias == null ? each.value.primary_records : null
}

### -----------------------------------------------------------------------------
### 8. 페일오버 라우팅 - Secondary 레코드
### -----------------------------------------------------------------------------
resource "aws_route53_record" "failover_secondary" {
  for_each = var.enable_failover_routing ? var.failover_records : {}

  zone_id = local.public_zone_id
  name    = each.value.name
  type    = each.value.type

  set_identifier = "${each.key}-secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  # Secondary는 헬스 체크 선택적 (장애 시 최후 수단이므로 생략 가능)
  health_check_id = each.value.secondary_health_check_key != null ? aws_route53_health_check.this[each.value.secondary_health_check_key].id : null

  dynamic "alias" {
    for_each = each.value.secondary_alias != null ? [each.value.secondary_alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  ttl     = each.value.secondary_alias == null ? each.value.ttl : null
  records = each.value.secondary_alias == null ? each.value.secondary_records : null
}

### -----------------------------------------------------------------------------
### 9. CloudWatch 알람 - 헬스 체크 실패 알림
### (enable_health_check_alarms = true 일 때만 생성)
### prod 환경에서 헬스 체크 실패 시 즉각적인 알림 필요
### -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "health_check" {
  for_each = var.enable_health_check_alarms ? var.health_checks : {}

  # CloudWatch 헬스 체크 알람은 반드시 us-east-1 리전에 생성해야 합니다
  # Route53 헬스 체크 메트릭은 글로벌 서비스이므로 us-east-1에서만 사용 가능
  provider = aws.us_east_1

  alarm_name          = "${local.name_prefix}-health-${each.key}"
  alarm_description   = "${each.value.fqdn} 헬스 체크 실패. 즉시 확인이 필요합니다."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-health-${each.key}-alarm"
  })
}

### -----------------------------------------------------------------------------
### 10. Route53 Resolver Outbound Endpoint (enable_resolver = true 일 때만 생성)
### 하이브리드 환경에서 온프레미스 DNS 서버로 쿼리 전달
### -----------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "outbound" {
  count = var.enable_resolver ? 1 : 0

  name      = "${local.name_prefix}-resolver-outbound"
  direction = "OUTBOUND"

  security_group_ids = var.resolver_security_group_ids

  dynamic "ip_address" {
    for_each = var.resolver_subnet_ids

    content {
      subnet_id = ip_address.value
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-resolver-outbound"
  })
}

### -----------------------------------------------------------------------------
### 11. Route53 Resolver Rule (enable_resolver = true 일 때만 생성)
### 특정 도메인을 온프레미스 DNS 서버로 전달하는 규칙
### -----------------------------------------------------------------------------
resource "aws_route53_resolver_rule" "forward" {
  for_each = var.enable_resolver ? var.resolver_rules : {}

  domain_name          = each.value.domain_name
  name                 = "${local.name_prefix}-resolver-rule-${each.key}"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound[0].id

  dynamic "target_ip" {
    for_each = each.value.target_ips

    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-resolver-rule-${each.key}"
  })
}

### -----------------------------------------------------------------------------
### 12. Route53 Resolver Rule Association (VPC와 연결)
### -----------------------------------------------------------------------------
resource "aws_route53_resolver_rule_association" "forward" {
  for_each = var.enable_resolver ? var.resolver_rules : {}

  resolver_rule_id = aws_route53_resolver_rule.forward[each.key].id
  vpc_id           = var.resolver_vpc_id
}

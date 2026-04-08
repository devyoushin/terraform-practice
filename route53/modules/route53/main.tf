### ============================================================
### modules/route53/main.tf
### AWS Route53 호스팅 존 및 레코드 리소스 정의
### ============================================================

### 새 호스팅 존 생성 - create_zone = true 일 때만 생성
resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name    = var.zone_name
  comment = var.zone_comment != "" ? var.zone_comment : "${var.project_name} ${var.environment} 호스팅 존"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-zone"
    Environment = var.environment
  })
}

### 기존 호스팅 존 참조 - create_zone = false 일 때만 데이터 소스 사용
data "aws_route53_zone" "this" {
  count = var.create_zone ? 0 : 1

  name         = var.zone_name
  private_zone = false
}

### 로컬 변수 - 새 생성 또는 기존 참조 중 하나의 zone_id 선택
locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}

### DNS 레코드 동적 생성
### - A, CNAME, MX, TXT, NS 등 다양한 타입 지원
### - alias 블록 동적 추가 지원 (ELB, CloudFront 등 AWS 리소스 연결 시 사용)
### - alias 사용 시 ttl 생략 (AWS에서 자동 관리)
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type

  ### alias 블록 - alias 설정이 있을 때만 추가 (ELB/CloudFront/S3 등 AWS 리소스 연결용)
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  ### ttl - alias 사용 시 생략 (alias와 ttl/records는 동시 사용 불가)
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null
}

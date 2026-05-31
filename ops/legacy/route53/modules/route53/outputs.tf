### =============================================================================
### modules/route53/outputs.tf
### Route53 모듈 출력값 정의
### =============================================================================

### -----------------------------------------------------------------------------
### 퍼블릭 호스팅 존 출력값
### -----------------------------------------------------------------------------

output "zone_id" {
  description = "퍼블릭 Route53 호스팅 존 ID. 다른 모듈에서 레코드를 추가할 때 사용합니다."
  value       = local.public_zone_id
}

output "zone_name_servers" {
  description = "퍼블릭 호스팅 존 네임서버 목록. 도메인 등록 기관(가비아, 후이즈 등)에 NS 레코드로 등록해야 합니다."
  value       = var.create_zone ? aws_route53_zone.public[0].name_servers : data.aws_route53_zone.public[0].name_servers
}

output "zone_arn" {
  description = "퍼블릭 Route53 호스팅 존 ARN."
  value       = var.create_zone ? aws_route53_zone.public[0].arn : data.aws_route53_zone.public[0].arn
}

output "zone_name" {
  description = "퍼블릭 호스팅 존 도메인 이름."
  value       = var.zone_name
}

### -----------------------------------------------------------------------------
### 프라이빗 호스팅 존 출력값 (enable_private_zone = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "private_zone_id" {
  description = "프라이빗 Route53 호스팅 존 ID. enable_private_zone = true 일 때만 값이 존재합니다."
  value       = var.enable_private_zone ? aws_route53_zone.private[0].zone_id : null
}

output "private_zone_name_servers" {
  description = "프라이빗 호스팅 존 네임서버 목록. enable_private_zone = true 일 때만 값이 존재합니다."
  value       = var.enable_private_zone ? aws_route53_zone.private[0].name_servers : null
}

### -----------------------------------------------------------------------------
### DNS 레코드 출력값
### -----------------------------------------------------------------------------

output "record_fqdns" {
  description = "퍼블릭 존에 생성된 DNS 레코드별 FQDN 맵 (키: records 맵의 키, 값: FQDN)."
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "private_record_fqdns" {
  description = "프라이빗 존에 생성된 DNS 레코드별 FQDN 맵."
  value       = { for k, v in aws_route53_record.private : k => v.fqdn }
}

### -----------------------------------------------------------------------------
### 헬스 체크 출력값 (enable_health_checks = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "health_check_ids" {
  description = "생성된 헬스 체크 ID 맵 (키: health_checks 맵의 키, 값: 헬스 체크 ID)."
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}

### -----------------------------------------------------------------------------
### 페일오버 레코드 출력값 (enable_failover_routing = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "failover_primary_fqdns" {
  description = "페일오버 Primary 레코드별 FQDN 맵."
  value       = { for k, v in aws_route53_record.failover_primary : k => v.fqdn }
}

output "failover_secondary_fqdns" {
  description = "페일오버 Secondary 레코드별 FQDN 맵."
  value       = { for k, v in aws_route53_record.failover_secondary : k => v.fqdn }
}

### -----------------------------------------------------------------------------
### Resolver 출력값 (enable_resolver = true 일 때만 유효)
### -----------------------------------------------------------------------------

output "resolver_endpoint_id" {
  description = "Route53 Resolver Outbound Endpoint ID. enable_resolver = true 일 때만 값이 존재합니다."
  value       = var.enable_resolver ? aws_route53_resolver_endpoint.outbound[0].id : null
}

output "resolver_endpoint_arn" {
  description = "Route53 Resolver Outbound Endpoint ARN."
  value       = var.enable_resolver ? aws_route53_resolver_endpoint.outbound[0].arn : null
}

output "resolver_rule_ids" {
  description = "생성된 Resolver Rule ID 맵."
  value       = { for k, v in aws_route53_resolver_rule.forward : k => v.id }
}

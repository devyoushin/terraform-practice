### ============================================================
### modules/route53/outputs.tf
### Route53 모듈 출력값 정의
### ============================================================

### 호스팅 존 기본 정보

output "zone_id" {
  description = "Route53 호스팅 존 ID"
  value       = local.zone_id
}

output "zone_name_servers" {
  description = "호스팅 존 네임서버 목록 (도메인 등록 기관에 설정 필요)"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.this[0].name_servers
}

output "zone_arn" {
  description = "Route53 호스팅 존 ARN"
  value       = var.create_zone ? aws_route53_zone.this[0].arn : data.aws_route53_zone.this[0].arn
}

### DNS 레코드 정보

output "record_fqdns" {
  description = "생성된 DNS 레코드별 FQDN 맵 (키: records 맵의 키, 값: FQDN)"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

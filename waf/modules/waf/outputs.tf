output "web_acl_id" {
  description = "WAF Web ACL ID. CloudFront 배포 설정의 web_acl_id에 사용합니다."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN. ALB/API Gateway 연결 및 로깅 설정 시 사용합니다."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "WAF Web ACL 이름."
  value       = aws_wafv2_web_acl.this.name
}

output "blocked_ip_set_arn" {
  description = "차단 IP Set ARN. blocked_ip_addresses가 없으면 null."
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].arn : null
}

output "allowed_ip_set_arn" {
  description = "허용 IP Set ARN. allowed_ip_addresses가 없으면 null."
  value       = length(aws_wafv2_ip_set.allowed_ips) > 0 ? aws_wafv2_ip_set.allowed_ips[0].arn : null
}

###
### ALB 모듈 - 출력값 정의
### 상위 모듈 또는 다른 모듈에서 참조 가능한 값 노출
###

### ============================================================
### ALB 기본 정보
### ============================================================

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름 (Route53 CNAME 또는 alias 레코드에 사용)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB Hosted Zone ID (Route53 alias 레코드 생성 시 필요)"
  value       = aws_lb.this.zone_id
}

### ============================================================
### 타겟 그룹 정보
### ============================================================

output "target_group_arn" {
  description = "타겟 그룹 ARN (EC2, ECS, EKS 등록에 사용)"
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "타겟 그룹 이름"
  value       = aws_lb_target_group.this.name
}

### ============================================================
### 보안 그룹 정보
### ============================================================

output "security_group_id" {
  description = "ALB 보안 그룹 ID (백엔드 인스턴스 보안 그룹 인바운드 규칙에 사용)"
  value       = aws_security_group.alb.id
}

### ============================================================
### 리스너 ARN
### ============================================================

output "http_listener_arn" {
  description = "HTTP(80) 리스너 ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS(443) 리스너 ARN (create_https_listener = false 이면 null)"
  value       = var.create_https_listener ? aws_lb_listener.https[0].arn : null
}

###
### staging 환경 - 출력값 정의
###

output "alb_dns_name" {
  description = "ALB DNS 이름 (staging 환경 접속 주소)"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "타겟 그룹 ARN (EC2, ECS 등록에 사용)"
  value       = module.alb.target_group_arn
}

output "security_group_id" {
  description = "ALB 보안 그룹 ID (백엔드 인스턴스 인바운드 규칙에 허용)"
  value       = module.alb.security_group_id
}

### ============================================================
### envs/dev/outputs.tf
### 개발 환경 출력값 정의
### module.rds의 주요 출력값을 상위로 노출
### ============================================================

output "db_endpoint" {
  description = "RDS 인스턴스 엔드포인트 (host:port 형식)"
  value       = module.rds.db_instance_endpoint
}

output "db_address" {
  description = "RDS 인스턴스 호스트 주소 (host만)"
  value       = module.rds.db_instance_address
}

output "db_port" {
  description = "RDS 인스턴스 포트 번호"
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "데이터베이스 이름"
  value       = module.rds.db_name
}

output "security_group_id" {
  description = "RDS 시큐리티 그룹 ID"
  value       = module.rds.security_group_id
}

### =============================================================================
### modules/elasticache/outputs.tf
### AWS ElastiCache Redis 모듈 출력값 정의
### =============================================================================

output "replication_group_id" {
  description = "ElastiCache 복제 그룹 ID."
  value       = aws_elasticache_replication_group.this.id
}

output "primary_endpoint_address" {
  description = "Primary 엔드포인트 주소 (쓰기 연결). 애플리케이션의 Redis 쓰기 연결에 사용합니다."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader 엔드포인트 주소 (읽기 연결). 복제본이 있을 때 읽기 트래픽 분산에 사용합니다."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "security_group_id" {
  description = "Redis 보안 그룹 ID. 앱 서버에서 이 보안 그룹으로의 6379 포트 접근을 허용하세요."
  value       = aws_security_group.this.id
}

output "port" {
  description = "Redis 포트 번호."
  value       = 6379
}

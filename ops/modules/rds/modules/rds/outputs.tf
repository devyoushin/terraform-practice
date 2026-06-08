### ============================================================
### modules/rds/outputs.tf
### RDS 모듈 출력값 정의
### ============================================================

### RDS 인스턴스 기본 정보

output "db_instance_id" {
  description = "RDS 인스턴스 ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS 인스턴스 ARN"
  value       = aws_db_instance.this.arn
}

### 접속 정보

output "db_instance_endpoint" {
  description = "RDS 인스턴스 엔드포인트 (host:port 형식)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "RDS 인스턴스 호스트 주소 (host만, 포트 제외)"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "RDS 인스턴스 포트 번호"
  value       = aws_db_instance.this.port
}

### DB 기본 정보

output "db_name" {
  description = "생성된 데이터베이스 이름"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "DB 마스터 사용자 이름"
  value       = aws_db_instance.this.username
}

### 네트워크/보안 정보

output "security_group_id" {
  description = "RDS에 연결된 시큐리티 그룹 ID"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "RDS 서브넷 그룹 이름"
  value       = aws_db_subnet_group.this.name
}

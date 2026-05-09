###############################################
# modules/vpc/outputs.tf
# 모듈 출력값 정의
###############################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "NAT Gateway ID 목록"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway 퍼블릭 IP 목록"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "퍼블릭 라우트 테이블 ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "프라이빗 라우트 테이블 ID 목록"
  value       = aws_route_table.private[*].id
}

output "s3_endpoint_id" {
  description = "S3 VPC Endpoint ID (비활성화 시 null)"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB VPC Endpoint ID (비활성화 시 null)"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "flow_log_id" {
  description = "VPC Flow Log ID (비활성화 시 null)"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

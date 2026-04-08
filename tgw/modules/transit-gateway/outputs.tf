output "id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.this.arn
}

output "owner_id" {
  description = "Transit Gateway 소유자 AWS 계정 ID"
  value       = aws_ec2_transit_gateway.this.owner_id
}

output "association_default_route_table_id" {
  description = "기본 연결 라우트 테이블 ID"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "propagation_default_route_table_id" {
  description = "기본 전파 라우트 테이블 ID"
  value       = aws_ec2_transit_gateway.this.propagation_default_route_table_id
}

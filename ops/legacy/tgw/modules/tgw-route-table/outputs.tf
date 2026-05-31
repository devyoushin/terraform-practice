output "id" {
  description = "TGW 라우트 테이블 ID"
  value       = aws_ec2_transit_gateway_route_table.this.id
}

output "arn" {
  description = "TGW 라우트 테이블 ARN"
  value       = aws_ec2_transit_gateway_route_table.this.arn
}

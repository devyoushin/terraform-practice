output "attachment_id" {
  description = "VPC 어태치먼트 ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "vpc_id" {
  description = "연결된 VPC ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.vpc_id
}

output "subnet_ids" {
  description = "어태치먼트에 사용된 서브넷 ID 목록"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids
}

output "resource_share_arn" {
  description = "RAM 리소스 공유 ARN"
  value       = aws_ram_resource_share.this.arn
}

output "resource_share_id" {
  description = "RAM 리소스 공유 ID"
  value       = aws_ram_resource_share.this.id
}

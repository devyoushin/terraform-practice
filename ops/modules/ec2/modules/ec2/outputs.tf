###############################################
# modules/ec2/outputs.tf
# 모듈 출력값 정의
###############################################

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 인스턴스 ARN"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "EC2 프라이빗 IP"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "EC2 퍼블릭 IP"
  value       = aws_instance.this.public_ip
}

output "elastic_ip" {
  description = "Elastic IP 주소"
  value       = var.create_eip ? aws_eip.this[0].public_ip : null
}

output "security_group_id" {
  description = "보안 그룹 ID"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "보안 그룹 ARN"
  value       = aws_security_group.this.arn
}

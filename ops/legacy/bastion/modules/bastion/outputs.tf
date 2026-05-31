###############################################
# modules/bastion/outputs.tf
# 모듈 출력값 정의
###############################################

output "instance_id" {
  description = "Bastion EC2 인스턴스 ID"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "Bastion EC2 인스턴스 ARN"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Bastion EC2 프라이빗 IP"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Bastion 퍼블릭 IP (EIP가 있으면 EIP, 없으면 인스턴스 퍼블릭 IP)"
  value       = var.create_eip && var.enable_ssh ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "security_group_id" {
  description = "Bastion 보안 그룹 ID"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "Bastion IAM Role ARN"
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "Bastion IAM Instance Profile 이름"
  value       = aws_iam_instance_profile.this.name
}

output "ssm_connect_command" {
  description = "SSM Session Manager 접속 명령어"
  value       = "aws ssm start-session --target ${aws_instance.this.id} --region ${data.aws_region.current.name}"
}

###############################################
# 현재 리전 데이터 소스 (ssm_connect_command에서 사용)
###############################################
data "aws_region" "current" {}

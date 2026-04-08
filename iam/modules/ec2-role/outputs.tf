###############################################################################
### EC2 Role 모듈 출력값
###############################################################################

output "role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "role_name" {
  description = "EC2 IAM Role 이름"
  value       = aws_iam_role.ec2_role.name
}

output "instance_profile_arn" {
  description = "EC2 Instance Profile ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = aws_iam_instance_profile.ec2_profile.name
}

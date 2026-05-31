###############################################################################
### EKS IRSA 모듈 출력값
###############################################################################

output "role_arn" {
  description = "EKS IRSA IAM Role ARN (ServiceAccount annotations에 사용)"
  value       = aws_iam_role.irsa_role.arn
}

output "role_name" {
  description = "EKS IRSA IAM Role 이름"
  value       = aws_iam_role.irsa_role.name
}

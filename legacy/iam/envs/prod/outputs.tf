###############################################################################
### PROD 환경 출력값
###############################################################################

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = module.ec2_role.role_arn
}

output "ec2_role_name" {
  description = "EC2 IAM Role 이름"
  value       = module.ec2_role.role_name
}

output "instance_profile_arn" {
  description = "EC2 Instance Profile ARN (EC2 인스턴스에 연결 시 사용)"
  value       = module.ec2_role.instance_profile_arn
}

output "instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = module.ec2_role.instance_profile_name
}

# CI/CD Role 사용 시 주석 해제
# output "cicd_role_arn" {
#   description = "GitHub Actions CI/CD IAM Role ARN"
#   value       = module.cicd_role.role_arn
# }

# EKS IRSA 사용 시 주석 해제
# output "app_irsa_role_arn" {
#   description = "EKS 앱용 IRSA IAM Role ARN"
#   value       = module.app_irsa.role_arn
# }

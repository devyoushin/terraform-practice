output "instance_id"         { value = module.bastion.instance_id;         description = "Bastion EC2 인스턴스 ID" }
output "private_ip"          { value = module.bastion.private_ip;          description = "Bastion 프라이빗 IP" }
output "security_group_id"   { value = module.bastion.security_group_id;   description = "Bastion 보안 그룹 ID" }
output "iam_role_arn"        { value = module.bastion.iam_role_arn;        description = "Bastion IAM Role ARN" }
output "ssm_connect_command" { value = module.bastion.ssm_connect_command; description = "SSM Session Manager 접속 명령어" }

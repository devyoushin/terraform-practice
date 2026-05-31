###############################################
# envs/dev/outputs.tf
###############################################

output "instance_id" {
  value = module.ec2.instance_id
}

output "public_ip" {
  value = module.ec2.public_ip
}

output "private_ip" {
  value = module.ec2.private_ip
}

output "security_group_id" {
  value = module.ec2.security_group_id
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${module.ec2.public_ip}"
}

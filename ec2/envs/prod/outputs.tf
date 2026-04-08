###############################################
# envs/prod/outputs.tf
###############################################

output "instance_id" {
  value = module.ec2.instance_id
}

output "instance_arn" {
  value = module.ec2.instance_arn
}

output "private_ip" {
  value     = module.ec2.private_ip
  sensitive = true  # prod IP는 민감 정보로 마스킹
}

output "elastic_ip" {
  value = module.ec2.elastic_ip
}

output "security_group_id" {
  value = module.ec2.security_group_id
}

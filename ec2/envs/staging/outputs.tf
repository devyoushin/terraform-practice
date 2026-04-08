###############################################
# envs/staging/outputs.tf
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

output "elastic_ip" {
  value = module.ec2.elastic_ip
}

output "security_group_id" {
  value = module.ec2.security_group_id
}

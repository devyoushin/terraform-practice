###############################################
# envs/staging/variables.tf
###############################################

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "owner" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"  # staging은 dev보다 큰 타입 기본값
}

variable "key_pair_name" {
  type = string
}

variable "allowed_ssh_cidr" {
  description = "SSH 허용 CIDR (Bastion 또는 VPN IP 권장)"
  type        = list(string)
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "create_eip" {
  type    = bool
  default = false
}

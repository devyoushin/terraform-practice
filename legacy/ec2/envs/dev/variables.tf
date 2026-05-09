###############################################
# envs/dev/variables.tf
###############################################

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "owner" {
  description = "리소스 담당자 이름 또는 팀명"
  type        = string
}

variable "vpc_id" {
  description = "DEV VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "DEV 서브넷 ID"
  type        = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"  # dev는 저렴한 타입 기본값
}

variable "key_pair_name" {
  type = string
}

variable "allowed_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  type    = number
  default = 20
}

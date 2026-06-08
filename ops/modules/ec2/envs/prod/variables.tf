###############################################
# envs/prod/variables.tf
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
  default = "t3.medium"  # prod 기본값 (실제 부하에 맞게 조정)
}

variable "key_pair_name" {
  type = string
}

variable "allowed_ssh_cidr" {
  description = "SSH 허용 CIDR (Bastion 또는 VPN IP만 허용)"
  type        = list(string)
}

variable "allowed_http_cidr" {
  description = "HTTP/HTTPS 허용 CIDR (ALB 또는 내부망)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "root_volume_size" {
  type    = number
  default = 50  # prod는 여유있게
}

variable "root_volume_iops" {
  type    = number
  default = 3000
}

variable "root_volume_throughput" {
  type    = number
  default = 125
}

variable "extra_ebs_volumes" {
  description = "추가 EBS 볼륨 (데이터 볼륨 등)"
  type = list(object({
    device_name = string
    volume_type = string
    volume_size = number
  }))
  default = []
}

variable "iam_instance_profile" {
  description = "EC2 IAM Instance Profile (CloudWatch/SSM 등)"
  type        = string
  default     = null
}

variable "create_eip" {
  type    = bool
  default = false
}

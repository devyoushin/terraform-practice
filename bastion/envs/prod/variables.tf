###
### prod 환경 - 변수 정의
###

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "owner" {
  description = "리소스 소유팀 또는 담당자"
  type        = string
  default     = "infra-team"
}

variable "vpc_id" {
  description = "Bastion을 배포할 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Bastion을 배포할 서브넷 ID (SSM 전용: 프라이빗 서브넷 권장)"
  type        = string
}

variable "ami_id" {
  description = "사용할 AMI ID (Amazon Linux 2023 권장)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

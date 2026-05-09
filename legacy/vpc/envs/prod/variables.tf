###############################################
# envs/prod/variables.tf
###############################################

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
  description = "담당자 또는 팀 이름"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "azs" {
  description = "사용할 가용 영역 목록 (prod는 3개 AZ 권장)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록"
  type        = list(string)
  default     = []
}

variable "flow_logs_retention_days" {
  description = "Flow Logs CloudWatch 보존 기간 (일)"
  type        = number
  default     = 90
}

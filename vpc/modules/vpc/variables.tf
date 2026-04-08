###############################################
# modules/vpc/variables.tf
# 모듈 입력 변수 정의
###############################################

# -----------------------------------------------
# 기본 식별 정보
# -----------------------------------------------
variable "project_name" {
  description = "프로젝트 이름 (리소스 이름 prefix)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전 (VPC Endpoint 서비스명 구성에 사용)"
  type        = string
  default     = "ap-northeast-2"
}

# -----------------------------------------------
# VPC
# -----------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR 블록 (예: 10.0.0.0/16)"
  type        = string
}

# -----------------------------------------------
# 가용 영역 및 서브넷
# -----------------------------------------------
variable "azs" {
  description = "사용할 가용 영역 목록 (서브넷 수와 동일하게 맞출 것)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록 (azs와 순서 동일)"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록 (azs와 순서 동일)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------
# NAT Gateway
# -----------------------------------------------
variable "enable_nat_gateway" {
  description = "NAT Gateway 생성 여부 (프라이빗 서브넷 인터넷 접근 필요 시 true)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "NAT Gateway를 1개만 사용 (true: 비용 절약, false: AZ별 생성으로 고가용성)"
  type        = bool
  default     = true
}

# -----------------------------------------------
# VPC Endpoint
# -----------------------------------------------
variable "enable_s3_endpoint" {
  description = "S3 VPC Gateway Endpoint 생성 여부 (무료, 인터넷 구간 없이 S3 접근)"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "DynamoDB VPC Gateway Endpoint 생성 여부 (무료)"
  type        = bool
  default     = false
}

# -----------------------------------------------
# VPC Flow Logs
# -----------------------------------------------
variable "enable_flow_logs" {
  description = "VPC Flow Logs 활성화 여부 (CloudWatch Logs에 저장)"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Flow Logs CloudWatch 보존 기간 (일)"
  type        = number
  default     = 30
}

# -----------------------------------------------
# 태그
# -----------------------------------------------
variable "common_tags" {
  description = "모든 리소스에 공통으로 붙일 태그"
  type        = map(string)
  default     = {}
}

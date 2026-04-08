###############################################
# modules/ec2/variables.tf
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

# -----------------------------------------------
# 네트워크
# -----------------------------------------------
variable "vpc_id" {
  description = "배포할 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "배포할 서브넷 ID"
  type        = string
}

variable "associate_public_ip" {
  description = "퍼블릭 IP 자동 할당 여부"
  type        = bool
  default     = false
}

# -----------------------------------------------
# 보안 그룹 인바운드 규칙
# -----------------------------------------------
variable "ingress_rules" {
  description = "보안 그룹 인바운드 규칙 목록"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

# -----------------------------------------------
# EC2 인스턴스
# -----------------------------------------------
variable "ami_id" {
  description = "사용할 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "key_pair_name" {
  description = "SSH Key Pair 이름"
  type        = string
}

variable "iam_instance_profile" {
  description = "EC2에 연결할 IAM Instance Profile 이름 (선택)"
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "EC2 세부 모니터링 활성화 (추가 비용 발생)"
  type        = bool
  default     = false
}

# -----------------------------------------------
# 스토리지
# -----------------------------------------------
variable "root_volume_size" {
  description = "루트 EBS 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

variable "root_volume_iops" {
  description = "루트 볼륨 IOPS (gp3 기본값: 3000)"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "루트 볼륨 처리량 MiB/s (gp3 기본값: 125)"
  type        = number
  default     = 125
}

variable "extra_ebs_volumes" {
  description = "추가 EBS 볼륨 목록 (선택)"
  type = list(object({
    device_name = string
    volume_type = string
    volume_size = number
  }))
  default = []
}

# -----------------------------------------------
# 기타
# -----------------------------------------------
variable "user_data" {
  description = "인스턴스 시작 스크립트 (User Data)"
  type        = string
  default     = null
}

variable "create_eip" {
  description = "Elastic IP 생성 여부"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 붙일 태그"
  type        = map(string)
  default     = {}
}

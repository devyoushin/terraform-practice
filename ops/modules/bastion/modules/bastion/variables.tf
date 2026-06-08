###############################################
# modules/bastion/variables.tf
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
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
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
  description = "배포할 서브넷 ID (SSM 전용이면 프라이빗 서브넷도 가능)"
  type        = string
}

# -----------------------------------------------
# EC2 인스턴스
# -----------------------------------------------
variable "ami_id" {
  description = "사용할 AMI ID (Amazon Linux 2023 권장)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------
# 접속 방식 설정
# -----------------------------------------------
variable "enable_ssh" {
  description = <<-EOT
    SSH Bastion 모드 활성화 여부
      true  → 퍼블릭 IP 할당, 22 포트 인바운드 허용 (SSH Bastion)
      false → 퍼블릭 IP 없음, 포트 오픈 없음 (SSM Session Manager 전용, 권장)
  EOT
  type        = bool
  default     = false  # SSM 전용이 기본값 (보안상 권장)
}

variable "key_pair_name" {
  description = "SSH Key Pair 이름 (enable_ssh = true 일 때 필요)"
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "SSH 접속을 허용할 IP 목록 (enable_ssh = true 일 때 사용, 내 IP로 제한 권장)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------
# 옵션
# -----------------------------------------------
variable "create_eip" {
  description = "Elastic IP 생성 여부 (고정 IP가 필요한 SSH Bastion에서 사용, enable_ssh = true 일 때만 적용)"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 붙일 태그"
  type        = map(string)
  default     = {}
}

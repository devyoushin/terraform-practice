###############################################
# envs/dev/main.tf
# DEV 환경 - EC2 모듈 호출
###############################################

provider "aws" {
  region = var.aws_region

  # AWS 계정 실수 방지: 허용된 계정 ID만 배포 가능
  # allowed_account_ids = ["123456789012"]  # ← 실제 AWS 계정 ID로 변경 (선택)

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = var.owner  # ← terraform.tfvars에서 입력
  }
}

module "ec2" {
  source = "../../modules/ec2"

  # 기본 정보
  project_name = var.project_name
  environment  = "dev"

  # 네트워크
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  associate_public_ip = true  # dev는 퍼블릭 IP 허용

  # 인스턴스
  ami_id        = var.ami_id
  instance_type = var.instance_type  # dev는 작은 타입 사용
  key_pair_name = var.key_pair_name

  # 보안 그룹 규칙
  ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # 스토리지
  root_volume_size = var.root_volume_size

  # 옵션
  create_eip                 = false  # dev는 EIP 불필요
  enable_detailed_monitoring = false  # dev는 세부 모니터링 불필요
  common_tags                = local.common_tags
}

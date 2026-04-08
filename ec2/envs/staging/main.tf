###############################################
# envs/staging/main.tf
# STAGING 환경 - EC2 모듈 호출
###############################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "staging"
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "ec2" {
  source = "../../modules/ec2"

  # 기본 정보
  project_name = var.project_name
  environment  = "staging"

  # 네트워크
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  associate_public_ip = false  # staging은 프라이빗 서브넷 권장

  # 인스턴스
  ami_id        = var.ami_id
  instance_type = var.instance_type  # staging은 prod와 동일한 타입 권장
  key_pair_name = var.key_pair_name

  # 보안 그룹 규칙
  ingress_rules = [
    {
      description = "SSH (Bastion에서만)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr  # Bastion 또는 VPN IP만 허용
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
  create_eip                 = var.create_eip
  enable_detailed_monitoring = true  # staging은 모니터링 활성화
  common_tags                = local.common_tags
}

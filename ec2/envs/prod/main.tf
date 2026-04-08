###############################################
# envs/prod/main.tf
# PROD 환경 - EC2 모듈 호출
###############################################

provider "aws" {
  region = var.aws_region

  # prod는 반드시 계정 ID 검증 권장 (실수 방지)
  # allowed_account_ids = ["123456789012"]  # ← 실제 PROD AWS 계정 ID로 변경

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

module "ec2" {
  source = "../../modules/ec2"

  # 기본 정보
  project_name = var.project_name
  environment  = "prod"

  # 네트워크
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  associate_public_ip = false  # prod는 반드시 프라이빗 서브넷 + ELB 구성 권장

  # 인스턴스
  ami_id        = var.ami_id
  instance_type = var.instance_type  # prod는 충분한 스펙 사용
  key_pair_name = var.key_pair_name

  # 보안 그룹 규칙
  ingress_rules = [
    {
      description = "SSH (Bastion만 허용)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr  # Bastion 또는 VPN IP만
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.allowed_http_cidr  # ALB 보안그룹 CIDR 또는 내부망
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_http_cidr
    }
  ]

  # 스토리지
  root_volume_size       = var.root_volume_size
  root_volume_iops       = var.root_volume_iops
  root_volume_throughput = var.root_volume_throughput
  extra_ebs_volumes      = var.extra_ebs_volumes

  # IAM 역할 (CloudWatch, SSM 등)
  iam_instance_profile = var.iam_instance_profile  # ← prod는 IAM 프로파일 필수 권장

  # 옵션
  create_eip                 = var.create_eip
  enable_detailed_monitoring = true  # prod는 세부 모니터링 필수
  common_tags                = local.common_tags
}

###############################################
# modules/bastion/main.tf
# 재사용 가능한 Bastion 모듈 - 실제 리소스 정의
#
# 지원 접속 방식:
#   1. SSH Bastion  : enable_ssh = true  → 퍼블릭 IP + 22 포트 오픈
#   2. SSM Session Manager : enable_ssh = false → 퍼블릭 IP 없음, 포트 오픈 없음 (권장)
###############################################

###############################################
# IAM Role (SSM Session Manager 접속용)
###############################################
resource "aws_iam_role" "this" {
  name = "${var.project_name}-${var.environment}-bastion-role"

  # EC2 서비스가 이 역할을 위임받을 수 있도록 허용
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-role"
  })
}

# SSM Session Manager 접속에 필요한 기본 정책
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent 실행에 필요한 정책
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2 인스턴스에 연결할 Instance Profile
resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-${var.environment}-bastion-profile"
  role = aws_iam_role.this.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-profile"
  })
}

###############################################
# 보안 그룹
# - SSH Bastion 모드 : 22 포트 인바운드 허용
# - SSM 전용 모드   : 인바운드 규칙 없음 (아웃바운드만으로 SSM 통신)
###############################################
resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for ${var.project_name} ${var.environment} bastion"
  vpc_id      = var.vpc_id

  # SSH 인바운드 규칙 (enable_ssh = true 일 때만 생성)
  dynamic "ingress" {
    for_each = var.enable_ssh ? toset(["ssh"]) : toset([])
    content {
      description = "SSH 접속 허용 (allowed_ssh_cidr에서만)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr
    }
  }

  # 아웃바운드 전체 허용 (SSM 연결 및 패키지 설치용)
  egress {
    description = "아웃바운드 전체 허용"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  })
}

###############################################
# EC2 인스턴스 (Bastion Host)
###############################################
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # IAM Instance Profile (SSM 접속에 필수)
  iam_instance_profile = aws_iam_instance_profile.this.name

  # SSH Bastion이면 퍼블릭 IP 할당, SSM 전용이면 불필요
  associate_public_ip_address = var.enable_ssh

  # SSH Bastion이면 Key Pair 사용, SSM 전용이면 불필요
  key_name = var.enable_ssh ? var.key_pair_name : null

  vpc_security_group_ids = [aws_security_group.this.id]

  # SSM Agent 최신화 및 CloudWatch Agent 설치
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  )

  # 루트 볼륨: gp3, 20GB, 암호화 (보안 강화)
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  # IMDSv2 강제 (SSRF 공격 방어)
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Bastion은 세부 모니터링 불필요 (추가 비용 절약)
  monitoring = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion"
  })
}

###############################################
# Elastic IP (선택)
# - SSH Bastion 모드이고 고정 IP가 필요할 때만 생성
# - SSM 전용 모드에서는 생성하지 않음
###############################################
resource "aws_eip" "this" {
  count    = var.create_eip && var.enable_ssh ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-eip"
  })
}

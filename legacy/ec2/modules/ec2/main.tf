###############################################
# modules/ec2/main.tf
# 재사용 가능한 EC2 모듈 - 실제 리소스 정의
###############################################

###############################################
# 보안 그룹
###############################################
resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for ${var.project_name} ${var.environment}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg"
  })
}

###############################################
# EC2 인스턴스
###############################################
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    delete_on_termination = true
    encrypted             = true
  }

  # 추가 EBS 볼륨 (선택사항)
  dynamic "ebs_block_device" {
    for_each = var.extra_ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data                   = var.user_data
  iam_instance_profile        = var.iam_instance_profile
  monitoring                  = var.enable_detailed_monitoring

  # 실수로 인한 인스턴스 삭제 방지 (prod 환경에서 권장)
  lifecycle {
    ignore_changes = [ami_id]  # AMI 업데이트 시 인스턴스 재생성 방지
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2"
  })
}

###############################################
# Elastic IP (선택사항)
###############################################
resource "aws_eip" "this" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eip"
  })
}

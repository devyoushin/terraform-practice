###
### ALB 모듈 - 메인 리소스 정의
### Application Load Balancer, 보안 그룹, 타겟 그룹, 리스너 생성
###

### ============================================================
### 보안 그룹 (Security Group)
### HTTP(80), HTTPS(443) 인바운드 허용 / 아웃바운드 전체 허용
### ============================================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "${var.project_name} ${var.environment} ALB Security Group"
  vpc_id      = var.vpc_id

  # HTTP 인바운드 허용
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS 인바운드 허용
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### ============================================================
### ACM 인증서 (AWS Certificate Manager)
### create_acm_certificate = true 일 때만 생성
### DNS 검증 방식 사용
### ============================================================
resource "aws_acm_certificate" "this" {
  count = var.create_acm_certificate ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  # 인증서 갱신 시 기존 인증서 삭제 전 새 인증서 생성
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-acm"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### ============================================================
### ALB (Application Load Balancer)
### enable_access_logs = true 일 때 S3 액세스 로그 활성화
### ============================================================
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  # 삭제 보호 (prod 환경 권장)
  enable_deletion_protection = var.enable_deletion_protection

  # 액세스 로그 설정 (enable_access_logs = true 일 때 활성화)
  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "${var.project_name}-${var.environment}-alb"
      enabled = true
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### ============================================================
### 타겟 그룹 (Target Group)
### target_type: instance / ip / lambda 선택 가능
### 헬스체크 경로 및 임계값 설정 포함
### ============================================================
resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  # 헬스체크 설정
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
    matcher             = var.health_check_matcher
  }

  # 타겟 그룹 교체 시 기존 타겟 그룹 삭제 전 새 타겟 그룹 생성
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### ============================================================
### HTTP 리스너 (포트 80)
### enable_https_redirect = true  → HTTPS(443)로 301 리다이렉트
### enable_https_redirect = false → 타겟 그룹으로 직접 포워딩
### ============================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # HTTPS 리다이렉트 활성화 여부에 따라 기본 액션 분기
  dynamic "default_action" {
    for_each = var.enable_https_redirect ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https_redirect ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### ============================================================
### HTTPS 리스너 (포트 443)
### create_https_listener = true 일 때만 생성
### acm_certificate_arn 우선 사용, 없으면 생성된 인증서 ARN 사용
### ============================================================
resource "aws_lb_listener" "https" {
  count = var.create_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # 기존 인증서 ARN 우선, 없으면 모듈에서 생성한 인증서 사용
  certificate_arn = var.acm_certificate_arn != null ? var.acm_certificate_arn : aws_acm_certificate.this[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-https-listener"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

### =============================================================================
### modules/cloudfront/main.tf
### AWS CloudFront CDN 배포를 생성하는 재사용 가능한 모듈
### =============================================================================

locals {
  tags = merge(var.common_tags, {
    Module      = "cloudfront"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. Origin Access Control (S3 오리진 직접 접근 차단)
### CloudFront를 통해서만 S3에 접근할 수 있도록 OAC 설정
### -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  count = var.s3_origin_bucket_domain != "" ? 1 : 0

  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "${var.environment} 환경 S3 오리진 접근 제어"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

### -----------------------------------------------------------------------------
### 2. CloudFront 배포
### S3 오리진(정적 파일) 또는 ALB 오리진(동적 콘텐츠) 지원
### -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CloudFront 배포"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  http_version        = "http2and3"

  # 커스텀 도메인 (ACM 인증서 필요)
  aliases = length(var.aliases) > 0 ? var.aliases : null

  # WAF Web ACL 연결 (선택적)
  web_acl_id = var.web_acl_id != "" ? var.web_acl_id : null

  ### S3 오리진 (정적 파일 서빙)
  dynamic "origin" {
    for_each = var.s3_origin_bucket_domain != "" ? [1] : []
    content {
      domain_name              = var.s3_origin_bucket_domain
      origin_id                = "S3Origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac[0].id
    }
  }

  ### ALB/Custom 오리진 (동적 콘텐츠)
  dynamic "origin" {
    for_each = var.alb_origin_domain != "" ? [1] : []
    content {
      domain_name = var.alb_origin_domain
      origin_id   = "ALBOrigin"
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  ### 기본 캐시 동작
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_origin_bucket_domain != "" ? "S3Origin" : "ALBOrigin"

    # HTTPS로 리다이렉트
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS 관리형 캐시 정책: CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # S3 오리진 사용 시 CORS-S3Origin 요청 정책 적용
    origin_request_policy_id = var.s3_origin_bucket_domain != "" ? "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" : null
  }

  ### 뷰어 인증서 설정
  viewer_certificate {
    # ACM 인증서 ARN이 있으면 커스텀 도메인 HTTPS 설정
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : "TLSv1"
    cloudfront_default_certificate = var.acm_certificate_arn == ""
  }

  ### 지역 제한 (없음)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  ### 액세스 로그 (선택적)
  dynamic "logging_config" {
    for_each = var.access_log_bucket != "" ? [1] : []
    content {
      bucket          = "${var.access_log_bucket}.s3.amazonaws.com"
      include_cookies = false
      prefix          = "cloudfront/${var.environment}/"
    }
  }

  tags = local.tags
}

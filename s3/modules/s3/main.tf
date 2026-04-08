### =============================================================================
### modules/s3/main.tf
### AWS S3 버킷 및 관련 리소스를 생성하는 재사용 가능한 모듈
### =============================================================================

### -----------------------------------------------------------------------------
### 로컬 변수
### -----------------------------------------------------------------------------
locals {
  # bucket_name이 명시적으로 지정된 경우 그것을 사용, 아니면 자동 생성
  bucket_name = var.bucket_name != null ? var.bucket_name : "${var.project_name}-${var.environment}-${var.bucket_suffix}"

  # 공통 태그 + 모듈 기본 태그 병합
  tags = merge(var.common_tags, {
    Module      = "s3"
    BucketName  = local.bucket_name
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. S3 버킷 생성
### -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. 퍼블릭 액세스 차단 (모든 환경에서 강제 적용)
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### -----------------------------------------------------------------------------
### 3. 버킷 버전관리
### enable_versioning = true  → Enabled
### enable_versioning = false → Suspended
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

### -----------------------------------------------------------------------------
### 4. 서버 사이드 암호화 설정
### kms_key_arn 미지정 → AES256 (S3 관리형 키)
### kms_key_arn 지정   → aws:kms (고객 관리형 키)
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      # KMS 키가 지정된 경우 aws:kms, 아니면 AES256 사용
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }

    # KMS 사용 시 버킷 키 활성화로 KMS API 호출 비용 절감
    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

### -----------------------------------------------------------------------------
### 5. 수명주기 규칙 (enable_lifecycle = true 일 때만 생성)
### 규칙 1: Noncurrent 버전 관리 (30일 → STANDARD_IA, 90일 → 삭제)
### 규칙 2: 미완성 멀티파트 업로드 7일 후 정리
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # 이전 버전 객체 전환 및 만료 규칙
  rule {
    id     = "noncurrent-version-management"
    status = "Enabled"

    # 모든 객체에 적용
    filter {
      prefix = ""
    }

    # 30일 후 STANDARD_IA로 전환 (접근 빈도 낮은 스토리지)
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # 90일 후 이전 버전 삭제
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # 미완성 멀티파트 업로드 정리 규칙 (스토리지 낭비 방지)
  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # 7일 이상 완료되지 않은 멀티파트 업로드 자동 삭제
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # 버전관리가 활성화된 후 수명주기 규칙 적용
  depends_on = [aws_s3_bucket_versioning.this]
}

### -----------------------------------------------------------------------------
### 6. 버킷 정책 (bucket_policy_json이 비어있지 않을 때만 생성)
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  count = var.bucket_policy_json != "" ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json

  # 퍼블릭 액세스 차단 설정 이후 정책 적용
  depends_on = [aws_s3_bucket_public_access_block.this]
}

### -----------------------------------------------------------------------------
### 7. CORS 설정 (cors_rules가 비어있지 않을 때만 생성)
### 예: 웹 애플리케이션에서 S3 직접 업로드 허용 시 필요
### -----------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # 각 CORS 규칙을 동적으로 생성
  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

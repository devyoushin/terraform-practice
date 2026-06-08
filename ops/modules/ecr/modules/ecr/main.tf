### =============================================================================
### modules/ecr/main.tf
### AWS ECR 레포지토리 및 관련 리소스를 생성하는 재사용 가능한 모듈
### =============================================================================

### -----------------------------------------------------------------------------
### 로컬 변수
### -----------------------------------------------------------------------------
locals {
  # repository_name이 명시적으로 지정된 경우 그것을 사용, 아니면 자동 생성
  repository_name = var.repository_name != null ? var.repository_name : "${var.project_name}-${var.environment}-${var.name_suffix}"

  # 공통 태그 + 모듈 기본 태그 병합
  tags = merge(var.common_tags, {
    Module      = "ecr"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. ECR 레포지토리 생성
### -----------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name                 = local.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  # 이미지 푸시 시 취약점 자동 스캔 (보안 강화)
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # 암호화 설정: KMS 또는 AES256
  encryption_configuration {
    encryption_type = var.encryption_type
    # KMS 암호화 타입일 때만 kms_key 지정
    kms_key = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. 이미지 수명주기 정책 (enable_lifecycle_policy = true 일 때만 생성)
### 규칙 1: 태그 없는 이미지 → N일 후 자동 삭제
### 규칙 2: 태그 있는 이미지 → 최신 N개만 유지
### -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        # 태그 없는 이미지 정리 (빌드 실패 잔여물 등)
        rulePriority = 1
        description  = "태그 없는 이미지 ${var.untagged_image_days}일 후 삭제"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      },
      {
        # 오래된 태그 이미지 정리 (최신 N개만 유지)
        rulePriority = 2
        description  = "태그 있는 이미지 최신 ${var.tagged_image_count}개만 유지"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v", "release", "latest"]
          countType   = "imageCountMoreThan"
          countNumber = var.tagged_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

### -----------------------------------------------------------------------------
### 3. 레포지토리 정책 (repository_policy_json이 비어있지 않을 때만 생성)
### 예: 다른 AWS 계정에서 이미지 풀 허용 (크로스 계정 접근)
### -----------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "this" {
  count = var.repository_policy_json != "" ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy_json
}

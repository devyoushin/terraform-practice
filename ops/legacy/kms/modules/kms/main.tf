### =============================================================================
### modules/kms/main.tf
### AWS KMS 키 및 별칭을 생성하는 재사용 가능한 모듈
### =============================================================================

### -----------------------------------------------------------------------------
### 로컬 변수
### -----------------------------------------------------------------------------
locals {
  # key_alias가 지정된 경우 그것을 사용, 아니면 자동 생성
  key_alias = var.key_alias != null ? var.key_alias : "alias/${var.project_name}-${var.environment}-${var.key_suffix}"

  tags = merge(var.common_tags, {
    Module      = "kms"
    Environment = var.environment
    KeySuffix   = var.key_suffix
  })
}

### -----------------------------------------------------------------------------
### 현재 AWS 계정 정보 조회
### -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

### -----------------------------------------------------------------------------
### 1. KMS 키 생성
### key_policy_json 미지정 시 계정 루트가 전체 권한을 가지는 기본 정책 사용
### -----------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  description              = "${var.project_name}-${var.environment}-${var.key_suffix} 암호화 키"
  key_usage                = var.key_usage
  customer_master_key_spec = var.key_spec

  # 키 삭제 전 대기 기간 (이 기간 동안 실수로 인한 삭제 취소 가능)
  deletion_window_in_days = var.deletion_window_in_days

  # 자동 키 교체 활성화 (대칭키만 지원, 연 1회 자동 교체)
  enable_key_rotation = var.enable_key_rotation

  is_enabled   = true
  multi_region = var.multi_region

  # 키 정책: 명시적으로 지정된 경우 사용, 아니면 null (AWS 기본 정책 적용)
  policy = var.key_policy_json != "" ? var.key_policy_json : null

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. KMS 키 별칭 생성
### 별칭을 통해 ARN 대신 사람이 읽기 쉬운 이름으로 키 참조 가능
### -----------------------------------------------------------------------------
resource "aws_kms_alias" "this" {
  name          = local.key_alias
  target_key_id = aws_kms_key.this.key_id
}

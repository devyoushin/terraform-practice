### =============================================================================
### modules/secrets-manager/main.tf
### AWS Secrets Manager 시크릿을 생성하는 재사용 가능한 모듈
### =============================================================================

locals {
  # secret_name이 지정된 경우 그것을 사용, 아니면 계층형 경로로 자동 생성
  secret_name = var.secret_name != null ? var.secret_name : "${var.project_name}/${var.environment}/${var.secret_suffix}"

  tags = merge(var.common_tags, {
    Module      = "secrets-manager"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. 시크릿 생성
### -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = var.description
  kms_key_id  = var.kms_key_arn

  # 시크릿 삭제 후 복구 가능 기간 (0이면 즉시 삭제, 그 외 7~30일)
  recovery_window_in_days = var.recovery_window_in_days

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. 시크릿 초기값 설정 (secret_string이 지정된 경우에만 생성)
### 초기값 설정 후 Terraform 외부에서 변경되는 것을 허용하기 위해
### lifecycle ignore_changes 적용
### -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "this" {
  count = var.secret_string != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string

  lifecycle {
    # 초기값 설정 후 애플리케이션이나 콘솔에서 변경된 값을 Terraform이 덮어쓰지 않도록 무시
    ignore_changes = [secret_string]
  }
}

### -----------------------------------------------------------------------------
### 3. 자동 교체 설정 (enable_rotation = true 일 때만 생성)
### Lambda 함수가 필요합니다 (RDS, Redshift 등 AWS 지원 교체 또는 커스텀 Lambda)
### -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    # 자동 교체 주기 (일 단위)
    automatically_after_days = var.rotation_days
  }
}

### -----------------------------------------------------------------------------
### 4. 시크릿 접근 정책 (secret_policy_json이 비어있지 않을 때만 생성)
### 예: 특정 IAM 역할이나 다른 계정에서 시크릿 조회 허용
### -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret_policy" "this" {
  count = var.secret_policy_json != "" ? 1 : 0

  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.secret_policy_json
}

### ============================================================
### modules/backup/main.tf
### AWS Backup 리소스 정의
### ============================================================

### ---------------------------------------------------------------
### IAM 역할 - AWS Backup 서비스가 리소스에 접근하기 위한 역할
### ---------------------------------------------------------------
resource "aws_iam_role" "backup" {
  name        = "${var.project_name}-${var.environment}-backup-role"
  description = "${var.project_name} ${var.environment} AWS Backup 서비스 역할"

  ### AWS Backup 서비스가 이 역할을 assume할 수 있도록 신뢰 정책 설정
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-backup-role"
    Environment = var.environment
  })
}

### AWS 관리형 정책 연결 - 백업 수행 권한
resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

### AWS 관리형 정책 연결 - 복원 수행 권한
resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

### ---------------------------------------------------------------
### 백업 볼트 - 백업 데이터를 저장하는 논리적 컨테이너 (KMS 암호화)
### ---------------------------------------------------------------
resource "aws_backup_vault" "this" {
  name        = "${var.project_name}-${var.environment}-${var.vault_name}"
  kms_key_arn = var.kms_key_arn

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-${var.vault_name}"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### 백업 플랜 - 백업 스케줄, 보존 기간, 라이프사이클 정의
### ---------------------------------------------------------------
resource "aws_backup_plan" "this" {
  name = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "${var.project_name}-${var.environment}-backup-rule"
    target_vault_name = aws_backup_vault.this.name

    ### 백업 스케줄 (cron 표현식)
    ### 기본값: cron(0 3 * * ? *) = 매일 UTC 새벽 3시 (KST 낮 12시)
    schedule = var.backup_schedule

    ### 백업 완료 대기 시간 (분) - 기본 60분 이내 백업 완료 기대
    start_window = 60

    ### 백업 완료 제한 시간 (분) - 120분 초과 시 실패 처리
    completion_window = 120

    ### 라이프사이클 설정 - 보존 기간 및 콜드 스토리지 전환
    lifecycle {
      ### 콜드 스토리지 전환 (optional) - null이면 비활성화
      cold_storage_after = var.cold_storage_after_days

      ### 백업 삭제 기간 (일) - 이 기간 이후 자동 삭제
      delete_after = var.delete_after_days
    }

    ### 복구 포인트 태그
    recovery_point_tags = merge(var.common_tags, {
      Environment = var.environment
    })
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-backup-plan"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### 백업 대상 선택 - 어떤 리소스를 백업할지 정의
### ARN 목록 또는 태그 기반으로 리소스 선택 가능
### ---------------------------------------------------------------
resource "aws_backup_selection" "this" {
  name         = "${var.project_name}-${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = aws_iam_role.backup.arn

  ### ARN 기반 리소스 선택 (명시적 지정)
  ### 비어 있으면 태그 기반 선택만 사용
  resources = var.resource_arns

  ### 태그 기반 리소스 선택 (optional)
  ### selection_tag 변수가 설정된 경우에만 생성
  dynamic "selection_tag" {
    for_each = var.selection_tag != null ? [var.selection_tag] : []

    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }
}

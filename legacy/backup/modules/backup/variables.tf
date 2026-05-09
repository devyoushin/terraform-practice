### ============================================================
### modules/backup/variables.tf
### AWS Backup 모듈 입력 변수 정의
### ============================================================

### 프로젝트 기본 정보

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment 변수는 dev, prod 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### 백업 볼트 설정

variable "vault_name" {
  description = "백업 볼트 이름 접미사 (전체 이름: <project>-<env>-<vault_name>)"
  type        = string
  default     = "Default"
}

variable "kms_key_arn" {
  description = "백업 볼트 암호화에 사용할 KMS 키 ARN (null이면 AWS 관리형 키 사용)"
  type        = string
  default     = null
}

### 백업 스케줄 설정

variable "backup_schedule" {
  description = "백업 스케줄 (cron 표현식, UTC 기준)\n예: cron(0 3 * * ? *) = 매일 새벽 3시 UTC (KST 낮 12시)"
  type        = string
  default     = "cron(0 3 * * ? *)"
}

### 백업 보존 기간 설정

variable "delete_after_days" {
  description = "백업 보존 기간 (일) - 이 기간 이후 자동 삭제\ndev: 7일 / staging: 14일 / prod: 30일"
  type        = number
  default     = 30

  validation {
    condition     = var.delete_after_days >= 1
    error_message = "delete_after_days는 1일 이상이어야 합니다."
  }
}

variable "cold_storage_after_days" {
  description = "콜드 스토리지로 전환하기까지의 일수 (optional)\nnull이면 콜드 스토리지 전환 비활성화\n주의: cold_storage_after_days는 delete_after_days보다 작아야 함"
  type        = number
  default     = null
}

### 백업 대상 리소스 설정

variable "resource_arns" {
  description = "백업할 리소스 ARN 목록 (명시적 지정)\n예: [\"arn:aws:rds:ap-northeast-2:123456789012:db:my-db\"]"
  type        = list(string)
  default     = []
}

variable "selection_tag" {
  description = "태그 기반 리소스 선택 설정 (optional)\n지정 시 해당 태그를 가진 모든 리소스가 백업 대상에 포함됨\n예: { type = \"STRINGEQUALS\", key = \"Backup\", value = \"true\" }"
  type = object({
    type  = string
    key   = string
    value = string
  })
  default = null
}

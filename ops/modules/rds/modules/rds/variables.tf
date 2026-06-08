### ============================================================
### modules/rds/variables.tf
### RDS 모듈 입력 변수 정의
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

### 네트워크 설정

variable "vpc_id" {
  description = "RDS를 배포할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "RDS 서브넷 그룹에 포함될 프라이빗 서브넷 ID 목록 (최소 2개, 가용 영역 분산 권장)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "RDS 접근을 허용할 CIDR 블록 목록 (애플리케이션 서버가 속한 서브넷 CIDR)"
  type        = list(string)
}

### DB 엔진 설정

variable "db_engine" {
  description = "DB 엔진 종류 (mysql / postgres 등)"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "DB 엔진 버전"
  type        = string
  default     = "8.0"
}

### 인스턴스 설정

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스 (환경별 차이: dev=db.t3.micro / staging=db.t3.small / prod=db.t3.medium)"
  type        = string
}

variable "db_name" {
  description = "생성할 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "DB 마스터 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "DB 마스터 사용자 비밀번호 (민감 정보 - tfvars에 직접 작성 금지, AWS Secrets Manager 또는 환경변수 사용 권장)"
  type        = string
  sensitive   = true
}

### 스토리지 설정

variable "allocated_storage" {
  description = "초기 할당 스토리지 크기 (GiB) - dev: 20 / staging: 50 / prod: 100"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "오토스케일링 최대 스토리지 크기 (GiB) - 0이면 오토스케일링 비활성화"
  type        = number
  default     = 100
}

### 가용성 설정

variable "multi_az" {
  description = "Multi-AZ 활성화 여부 (dev/staging: false 비용 절약 / prod: true 고가용성)"
  type        = bool
  default     = false
}

### 백업 설정

variable "backup_retention_period" {
  description = "자동 백업 보존 기간 (일) - dev: 7 / staging: 7 / prod: 30"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "자동 백업 수행 시간 창 (UTC, 예: 03:00-04:00)"
  type        = string
  default     = "03:00-04:00"
}

### 유지보수 설정

variable "maintenance_window" {
  description = "유지보수 수행 시간 창 (예: Mon:04:00-Mon:05:00)"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

### 삭제/스냅샷 보호 설정

variable "deletion_protection" {
  description = "삭제 방지 활성화 여부 (dev/staging: false / prod: true)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략 여부 (dev: true / staging/prod: false)"
  type        = bool
  default     = true
}

### 변경 적용 설정

variable "apply_immediately" {
  description = "변경 사항 즉시 적용 여부 (dev: true / prod: false - 유지보수 창에만 적용)"
  type        = bool
  default     = false
}

### 모니터링 설정

variable "enable_performance_insights" {
  description = "Performance Insights 활성화 여부 (dev/staging: false / prod: true)"
  type        = bool
  default     = false
}

### 공통 태그

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### ============================================================
### envs/staging/variables.tf
### 스테이징 환경 입력 변수 정의
### ============================================================

### AWS 기본 설정

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

### 프로젝트 정보

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "owner" {
  description = "리소스 소유자 또는 팀 이름 (태그에 사용)"
  type        = string
}

### 네트워크 설정

variable "vpc_id" {
  description = "RDS를 배포할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "RDS 서브넷 그룹에 포함될 프라이빗 서브넷 ID 목록 (최소 2개)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "RDS 접근을 허용할 CIDR 블록 목록 (VPC CIDR 또는 애플리케이션 서브넷)"
  type        = list(string)
}

### DB 설정

variable "db_name" {
  description = "생성할 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "DB 마스터 사용자 이름"
  type        = string
}

variable "db_password" {
  description = "DB 마스터 비밀번호 (민감 정보 - AWS Secrets Manager 또는 환경변수로 주입 권장)"
  type        = string
  sensitive   = true
}

### 인스턴스 설정

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스 (staging 기본값: db.t3.small)"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "초기 할당 스토리지 크기 (GiB)"
  type        = number
  default     = 50
}

### =============================================================================
### envs/prod/variables.tf
### 운영(prod) 환경 입력 변수 정의
### =============================================================================

variable "aws_region" {
  description = "AWS 리소스를 배포할 리전. 기본값: 서울 리전(ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름. S3 버킷 이름 자동 생성 패턴에 사용됩니다: {project_name}-prod-{bucket_suffix}"
  type        = string
}

variable "owner" {
  description = "리소스 소유자 또는 담당 팀. 태그에 사용됩니다."
  type        = string
  default     = "infra-team"
}

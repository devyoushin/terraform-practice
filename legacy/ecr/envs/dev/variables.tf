### =============================================================================
### envs/dev/variables.tf
### 개발(dev) 환경 입력 변수 정의
### =============================================================================

variable "aws_region" {
  description = "AWS 리소스를 배포할 리전. 기본값: 서울 리전(ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름. ECR 레포지토리 이름 자동 생성 패턴에 사용됩니다: {project_name}-dev-{name_suffix}"
  type        = string
}

variable "owner" {
  description = "리소스 소유자 또는 담당 팀. 태그에 사용됩니다."
  type        = string
  default     = "dev-team"
}

###############################################
# envs/dev/variables.tf
###############################################

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "owner" {
  description = "리소스 담당자 이름 또는 팀명"
  type        = string
}

variable "source_provider" {
  description = "소스 제공자 (CodeCommit 또는 S3)"
  type        = string
  default     = "CodeCommit"
}

variable "repository_name" {
  description = "CodeCommit 저장소 이름 또는 S3 버킷 이름"
  type        = string
}

variable "branch_name" {
  description = "빌드할 브랜치 이름"
  type        = string
  default     = "develop"
}

variable "buildspec_path" {
  description = "buildspec 파일 경로"
  type        = string
  default     = "buildspec.yml"
}

variable "ecs_cluster_name" {
  description = "ECS 클러스터 이름"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "ECS 서비스 이름"
  type        = string
  default     = ""
}

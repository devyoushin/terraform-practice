###############################################
# envs/prod/variables.tf
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
  default     = "main"
}

variable "buildspec_path" {
  description = "buildspec 파일 경로"
  type        = string
  default     = "buildspec.yml"
}

variable "deploy_app_name" {
  description = "CodeDeploy 애플리케이션 이름 (Blue/Green 배포 시 필수)"
  type        = string
  default     = ""
}

variable "deploy_group_name" {
  description = "CodeDeploy 배포 그룹 이름 (Blue/Green 배포 시 필수)"
  type        = string
  default     = ""
}

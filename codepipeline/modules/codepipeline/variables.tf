### ============================================================
### modules/codepipeline/variables.tf
### CodePipeline 모듈 입력 변수 정의
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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment 변수는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}

### 파이프라인 기본 설정

variable "pipeline_name" {
  description = "CodePipeline 파이프라인 이름 (빈 값이면 {project_name}-{environment}-pipeline 자동 생성)"
  type        = string
  default     = ""
}

### 소스 설정

variable "source_provider" {
  description = "소스 제공자 (CodeCommit 또는 S3)"
  type        = string
  default     = "CodeCommit"

  validation {
    condition     = contains(["CodeCommit", "S3"], var.source_provider)
    error_message = "source_provider는 CodeCommit 또는 S3 중 하나여야 합니다."
  }
}

variable "repository_name" {
  description = "CodeCommit 저장소 이름 또는 S3 버킷 이름"
  type        = string
}

variable "branch_name" {
  description = "빌드할 브랜치 이름 (S3 소스의 경우 Object Key 접두사)"
  type        = string
  default     = "main"
}

### CodeBuild 설정

variable "build_compute_type" {
  description = "CodeBuild 컴퓨팅 타입 (BUILD_GENERAL1_SMALL / MEDIUM / LARGE)"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE"], var.build_compute_type)
    error_message = "build_compute_type은 BUILD_GENERAL1_SMALL, MEDIUM, LARGE 중 하나여야 합니다."
  }
}

variable "build_image" {
  description = "CodeBuild 빌드 이미지"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "buildspec_path" {
  description = "buildspec 파일 경로 (저장소 루트 기준)"
  type        = string
  default     = "buildspec.yml"
}

### 배포 설정

variable "deploy_provider" {
  description = "배포 제공자 (ECS: Rolling / CodeDeployToECS: Blue-Green / CloudFormation)"
  type        = string
  default     = "ECS"

  validation {
    condition     = contains(["ECS", "CodeDeployToECS", "CloudFormation"], var.deploy_provider)
    error_message = "deploy_provider는 ECS, CodeDeployToECS, CloudFormation 중 하나여야 합니다."
  }
}

### ECS 배포 설정 (deploy_provider = "ECS" 시 필요)

variable "ecs_cluster_name" {
  description = "ECS 클러스터 이름 (deploy_provider = ECS 시 필수)"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "ECS 서비스 이름 (deploy_provider = ECS 시 필수)"
  type        = string
  default     = ""
}

### CodeDeploy Blue/Green 설정 (deploy_provider = "CodeDeployToECS" 시 필요)

variable "deploy_app_name" {
  description = "CodeDeploy 애플리케이션 이름 (deploy_provider = CodeDeployToECS 시 필수)"
  type        = string
  default     = ""
}

variable "deploy_group_name" {
  description = "CodeDeploy 배포 그룹 이름 (deploy_provider = CodeDeployToECS 시 필수)"
  type        = string
  default     = ""
}

### 로그 및 스토리지 설정

variable "log_retention_days" {
  description = "CloudWatch 빌드 로그 보존 기간 (일)"
  type        = number
  default     = 30
}

variable "artifact_bucket_force_destroy" {
  description = "아티팩트 S3 버킷 강제 삭제 여부 (dev: true, staging/prod: false)"
  type        = bool
  default     = false
}

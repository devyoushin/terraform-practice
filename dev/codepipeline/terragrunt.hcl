### =============================================================================
### dev/codepipeline/terragrunt.hcl
### DEV 환경 CodePipeline (CI/CD 파이프라인)
###
### 역할: 소스(GitHub/CodeCommit) → 빌드(CodeBuild) → 배포(ECS/EKS) 자동화
###       컨테이너 이미지를 ECR에 push하고 ECS 서비스를 자동 업데이트
### DEV 특징:
###   - deploy_type = "ECS_ROLLING": 롤링 배포 (Blue/Green 없이 단순 교체)
###     prod: "ECS_BLUE_GREEN" (무중단 배포)
###   - codebuild_compute_type = "BUILD_GENERAL1_SMALL": 최소 빌드 용량
###   - log_retention_days = 7: 빌드 로그 7일 보존
###   - artifact_force_delete = true: 아티팩트 S3 버킷 강제 삭제 가능
### 의존성: ecr/app (ECR 리포지토리 URL이 파이프라인 빌드 단계에 필요)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "ecr_app" {
  config_path = "../ecr/app"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    repository_name = "terraform-practice-app"
    repository_arn  = "arn:aws:ecr:ap-northeast-2:123456789012:repository/terraform-practice-app"
    repository_url  = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/terraform-practice-app"
    registry_id     = "123456789012"
  }
}

terraform {
  source = "../../codepipeline/modules/codepipeline"
}

inputs = {
  # ---------------------------------------------------------------
  # 파이프라인 이름
  # ---------------------------------------------------------------
  pipeline_name = "terraform-practice-dev-pipeline"

  # ---------------------------------------------------------------
  # 배포 방식
  # ECS_ROLLING: 기존 태스크를 새 버전으로 순차 교체 (간단, 짧은 다운타임)
  # ECS_BLUE_GREEN: 블루/그린 배포 (무중단, CodeDeploy 사용)
  # dev: 단순 롤링 배포 (설정 간편)
  # prod: 블루/그린 (무중단 배포, 즉각 롤백 가능)
  # ---------------------------------------------------------------
  deploy_type = "ECS_ROLLING"

  # ---------------------------------------------------------------
  # CodeBuild 컴퓨팅 용량
  # BUILD_GENERAL1_SMALL:  3 GB RAM, 2 vCPU (dev: 비용 절약)
  # BUILD_GENERAL1_MEDIUM: 7 GB RAM, 4 vCPU
  # BUILD_GENERAL1_LARGE:  15 GB RAM, 8 vCPU (prod: 빠른 빌드)
  # ---------------------------------------------------------------
  codebuild_compute_type = "BUILD_GENERAL1_SMALL"

  # ---------------------------------------------------------------
  # 빌드 로그 보존
  # dev: 7일 (디버깅 후 빠른 정리)
  # prod: 30일 이상 (빌드 이력 감사)
  # ---------------------------------------------------------------
  log_retention_days = 7

  # ---------------------------------------------------------------
  # ECR 리포지토리 — ecr/app 출력값 참조
  # 빌드된 Docker 이미지를 이 URL로 push
  # ---------------------------------------------------------------
  ecr_repository_url = dependency.ecr_app.outputs.repository_url

  # ---------------------------------------------------------------
  # ECS 배포 대상 설정
  # 실제 ECS 클러스터와 서비스 이름으로 교체 필요
  # ECS 모듈 미사용 시 직접 이름 지정
  # ---------------------------------------------------------------
  ecs_cluster_name = "terraform-practice-dev-cluster" # ECS 클러스터 이름
  ecs_service_name = "terraform-practice-dev-service" # ECS 서비스 이름

  # ---------------------------------------------------------------
  # 소스 설정 (GitHub 연결)
  # GitHub 연결: AWS CodeStar Connections에서 사전 설정 필요
  # CLI: aws codestar-connections create-connection --provider-type GitHub
  # ---------------------------------------------------------------
  source_provider         = "GitHub"
  github_repo_owner       = "your-github-org"   # GitHub 조직/사용자명으로 교체
  github_repo_name        = "your-app-repo"     # 저장소 이름으로 교체
  github_branch           = "develop"           # dev 브랜치

  # ---------------------------------------------------------------
  # 아티팩트 S3 버킷 설정
  # 파이프라인 아티팩트(빌드 결과물)를 저장하는 S3 버킷
  # dev: force_delete = true (terraform destroy 시 버킷 내 아티팩트 포함 삭제)
  # prod: force_delete = false (아티팩트 보호)
  # ---------------------------------------------------------------
  artifact_force_delete = true
}

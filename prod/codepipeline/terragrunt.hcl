### =============================================================================
### prod/codepipeline/terragrunt.hcl
### PROD 환경 CodePipeline — CI/CD 파이프라인
###
### 역할: 소스 → 빌드 → 테스트 → 배포 자동화
###   - CodeCommit/GitHub → CodeBuild → CodeDeploy (ECS Blue/Green)
###   - Docker 이미지 빌드 → ECR 푸시 → ECS 배포
###   - 아티팩트 S3 저장 (빌드 결과물)
###
### PROD 특징:
###   - deploy_type = "ECS_BLUE_GREEN"      (무중단 Blue/Green 배포)
###   - codebuild_compute_type = "BUILD_GENERAL1_MEDIUM" (빌드 성능)
###   - log_retention_days = 90             (빌드 로그 90일 보존)
###   - artifact_force_delete = false       (아티팩트 보호)
###
### 의존성:
###   - ecr/app  → ECR 레지스트리 URL (Docker 이미지 푸시 대상)
###   - s3/logs  → 아티팩트 저장 S3 버킷
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ prod 배포는 수동 승인(Manual Approval) 단계 추가 강력 권장
### ⚠️ GitHub 연동 시 OAuth 토큰 또는 CodeStar Connection 설정 필요
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "ecr_app" {
  config_path = "../ecr/app"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    repository_name = "terraform-practice-prod-app"
    repository_arn  = "arn:aws:ecr:ap-northeast-2:123456789012:repository/terraform-practice-prod-app"
    repository_url  = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/terraform-practice-prod-app"
    registry_id     = "123456789012"
  }
}

dependency "s3_logs" {
  config_path = "../s3/logs"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id  = "terraform-practice-prod-logs-123456789012"
    bucket_arn = "arn:aws:s3:::terraform-practice-prod-logs-123456789012"
  }
}

terraform {
  source = "../../codepipeline/modules/codepipeline"
}

inputs = {
  # ---------------------------------------------------------------
  # ECR 레지스트리 설정
  # CodeBuild에서 빌드한 Docker 이미지를 이 레지스트리에 푸시
  # ---------------------------------------------------------------
  ecr_repository_url  = dependency.ecr_app.outputs.repository_url
  ecr_repository_name = dependency.ecr_app.outputs.repository_name

  # ---------------------------------------------------------------
  # 아티팩트 저장소 (S3)
  # 파이프라인 각 단계 간 전달되는 빌드 결과물 저장
  # ---------------------------------------------------------------
  artifact_bucket = dependency.s3_logs.outputs.bucket_id

  # ---------------------------------------------------------------
  # 배포 유형
  # prod: ECS_BLUE_GREEN — 무중단 배포
  #   Blue: 현재 실행 중인 Task Set
  #   Green: 새 버전 Task Set
  #   → 트래픽을 Blue에서 Green으로 점진적 이동 (롤백 용이)
  # dev:  ECS_ROLLING    — 순차 배포 (단순하지만 다운타임 가능)
  # ---------------------------------------------------------------
  deploy_type = "ECS_BLUE_GREEN"

  # ---------------------------------------------------------------
  # CodeBuild 컴퓨팅 타입
  # prod: BUILD_GENERAL1_MEDIUM — 7GB RAM, 4 vCPU (빠른 빌드)
  # dev:  BUILD_GENERAL1_SMALL  — 3GB RAM, 2 vCPU (비용 절약)
  #
  # 빌드 시간 단축이 중요한 prod에서는 MEDIUM 이상 권장
  # 대규모 모노레포: BUILD_GENERAL1_LARGE (15GB RAM, 8 vCPU)
  # ---------------------------------------------------------------
  codebuild_compute_type = "BUILD_GENERAL1_MEDIUM"

  # ---------------------------------------------------------------
  # 빌드 로그 보존 기간
  # prod: 90일 — 장애 원인 분석 및 감사 로그 보존
  # dev:  7일  — 비용 절약
  # ---------------------------------------------------------------
  log_retention_days = 90

  # ---------------------------------------------------------------
  # 아티팩트 보호
  # prod: false — 아티팩트(빌드 결과물) 실수 삭제 방지
  # dev:  true  — 환경 정리 시 아티팩트 포함 삭제 허용
  # ---------------------------------------------------------------
  artifact_force_delete = false

  # ---------------------------------------------------------------
  # 소스 설정
  # GitHub 연동 방법:
  #   1. AWS 콘솔 → CodePipeline → Connections → GitHub 연결
  #   2. connection_arn을 아래에 입력
  #
  # ⚠️ GitHub OAuth 토큰을 이 파일에 절대 하드코딩하지 마세요!
  #    CodeStar Connection (IAM 기반) 방식 권장
  # ---------------------------------------------------------------
  # source_provider      = "GitHub"
  # github_repo_owner    = "REPLACE_WITH_GITHUB_ORG"
  # github_repo_name     = "REPLACE_WITH_REPO_NAME"
  # github_branch        = "main"
  # codestar_connection_arn = "REPLACE_WITH_CODESTAR_CONNECTION_ARN"

  # ---------------------------------------------------------------
  # 수동 승인 단계 (강력 권장)
  # prod 배포 전 팀 리더 승인을 필수로 설정
  # 승인 알림은 cloudwatch의 SNS 토픽 활용
  # ---------------------------------------------------------------
  enable_manual_approval = true
  approval_notify_email  = "REPLACE_WITH_APPROVAL_EMAIL"

  # ---------------------------------------------------------------
  # 빌드 스펙 (buildspec.yml)
  # 기본값: 소스 루트의 buildspec.yml 파일 사용
  # 커스텀 경로 지정 시:
  # buildspec_path = "infra/buildspec.yml"
  # ---------------------------------------------------------------
}

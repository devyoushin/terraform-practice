### ============================================================
### modules/codepipeline/main.tf
### AWS CodePipeline CI/CD 파이프라인 및 관련 리소스 정의
### ============================================================

### ---------------------------------------------------------------
### 아티팩트 저장 S3 버킷
### ---------------------------------------------------------------

### 파이프라인 아티팩트 저장 버킷
resource "aws_s3_bucket" "artifact" {
  bucket        = "${var.project_name}-${var.environment}-pipeline-artifacts"
  force_destroy = var.artifact_bucket_force_destroy

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-pipeline-artifacts"
    Environment = var.environment
  })
}

### 아티팩트 버킷 버저닝 활성화
resource "aws_s3_bucket_versioning" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  versioning_configuration {
    status = "Enabled"
  }
}

### 아티팩트 버킷 서버 사이드 암호화 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

### 아티팩트 버킷 퍼블릭 액세스 완전 차단
resource "aws_s3_bucket_public_access_block" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### ---------------------------------------------------------------
### CodePipeline IAM 역할 및 정책
### ---------------------------------------------------------------

### CodePipeline 실행 역할
resource "aws_iam_role" "pipeline_role" {
  name = "${var.project_name}-${var.environment}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-pipeline-role"
    Environment = var.environment
  })
}

### CodePipeline 실행 정책
### S3, CodeBuild, CodeDeploy, CodeCommit 접근 권한 부여
resource "aws_iam_role_policy" "pipeline_policy" {
  name = "${var.project_name}-${var.environment}-pipeline-policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      ### S3 아티팩트 버킷 접근 권한
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifact.arn,
          "${aws_s3_bucket.artifact.arn}/*"
        ]
      },
      ### CodeBuild 실행 권한
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ]
        Resource = "*"
      },
      ### CodeDeploy 실행 권한
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      ### CodeCommit 소스 접근 권한
      {
        Effect = "Allow"
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ]
        Resource = "*"
      },
      ### ECS 배포 권한
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      ### IAM PassRole 권한 (ECS 태스크 역할 전달용)
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "cloudformation.amazonaws.com"
            ]
          }
        }
      },
      ### CloudFormation 배포 권한 (CloudFormation deploy_provider용)
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
      }
    ]
  })
}

### ---------------------------------------------------------------
### CodeBuild IAM 역할 및 정책
### ---------------------------------------------------------------

### CodeBuild 실행 역할
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-codebuild-role"
    Environment = var.environment
  })
}

### CodeBuild 개발자 액세스 정책 연결
resource "aws_iam_role_policy_attachment" "codebuild_developer_access" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

### CloudWatch Logs 풀 액세스 정책 연결 (빌드 로그 저장용)
resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

### CodeBuild S3 아티팩트 접근 인라인 정책
resource "aws_iam_role_policy" "codebuild_s3_policy" {
  name = "${var.project_name}-${var.environment}-codebuild-s3-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifact.arn,
          "${aws_s3_bucket.artifact.arn}/*"
        ]
      }
    ]
  })
}

### ---------------------------------------------------------------
### CodeBuild 프로젝트
### ---------------------------------------------------------------

### CodeBuild 빌드 프로젝트 (buildspec.yml 기반)
resource "aws_codebuild_project" "this" {
  name          = "${var.project_name}-${var.environment}-build"
  description   = "${var.project_name} ${var.environment} 환경 CodeBuild 빌드 프로젝트"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild_role.arn

  ### 빌드 아티팩트 - CodePipeline 연동 시 CODEPIPELINE 타입 사용
  artifacts {
    type = "CODEPIPELINE"
  }

  ### 빌드 캐시 - 로컬 캐시로 빌드 속도 향상
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  ### 빌드 환경 설정
  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    ### 도커 빌드 활성화 여부 (ECS 이미지 빌드 시 필요)
    privileged_mode = true

    ### 빌드 환경 변수 - 프로젝트/환경 정보 주입
    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  ### 빌드 소스 - buildspec.yml 경로 지정
  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path
  }

  ### CloudWatch 로그 설정
  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build-log"
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-build"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### CloudWatch 로그 그룹
### ---------------------------------------------------------------

### CodeBuild 빌드 로그 그룹
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}-build"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name        = "/aws/codebuild/${var.project_name}-${var.environment}-build"
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### CodePipeline 파이프라인
### 3단계 구성: Source → Build → Deploy
### ---------------------------------------------------------------

resource "aws_codepipeline" "this" {
  name     = local.pipeline_name
  role_arn = aws_iam_role.pipeline_role.arn

  ### 아티팩트 저장 위치
  artifact_store {
    location = aws_s3_bucket.artifact.bucket
    type     = "S3"
  }

  ### ---------------------------------------------------------------
  ### Stage 1: Source
  ### CodeCommit 레포지토리 또는 S3 버킷에서 소스 가져오기
  ### source_provider 변수로 선택 (기본값: CodeCommit)
  ### ---------------------------------------------------------------
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = var.source_provider
      version          = "1"
      output_artifacts = ["source_output"]

      ### CodeCommit 소스 설정
      configuration = var.source_provider == "CodeCommit" ? {
        RepositoryName       = var.repository_name
        BranchName           = var.branch_name
        OutputArtifactFormat = "CODE_ZIP"
        } : {
        ### S3 소스 설정 (source_provider = "S3"일 때)
        S3Bucket             = var.repository_name
        S3ObjectKey          = "${var.branch_name}/source.zip"
        PollForSourceChanges = "true"
      }
    }
  }

  ### ---------------------------------------------------------------
  ### Stage 2: Build
  ### CodeBuild 프로젝트로 빌드/테스트 실행
  ### ---------------------------------------------------------------
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  ### ---------------------------------------------------------------
  ### Stage 3: Deploy
  ### deploy_provider 변수로 배포 대상 선택
  ###   - "CodeDeployToECS": CodeDeploy를 통한 ECS Blue/Green 배포
  ###   - "ECS":             직접 ECS 서비스 업데이트 (Rolling)
  ###   - "CloudFormation":  CloudFormation 스택 배포
  ### ---------------------------------------------------------------
  stage {
    name = "Deploy"

    dynamic "action" {
      ### CodeDeploy to ECS (Blue/Green 배포)
      for_each = var.deploy_provider == "CodeDeployToECS" ? [1] : []
      content {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeployToECS"
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = {
          ApplicationName                = var.deploy_app_name
          DeploymentGroupName            = var.deploy_group_name
          TaskDefinitionTemplateArtifact = "build_output"
          AppSpecTemplateArtifact        = "build_output"
        }
      }
    }

    dynamic "action" {
      ### ECS 직접 배포 (Rolling 업데이트)
      for_each = var.deploy_provider == "ECS" ? [1] : []
      content {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = {
          ClusterName = var.ecs_cluster_name
          ServiceName = var.ecs_service_name
          FileName    = "imagedefinitions.json"
        }
      }
    }

    dynamic "action" {
      ### CloudFormation 스택 배포
      for_each = var.deploy_provider == "CloudFormation" ? [1] : []
      content {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CloudFormation"
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = {
          ActionMode    = "CREATE_UPDATE"
          StackName     = "${var.project_name}-${var.environment}-stack"
          TemplatePath  = "build_output::template.yaml"
          Capabilities  = "CAPABILITY_IAM,CAPABILITY_NAMED_IAM"
          RoleArn       = aws_iam_role.pipeline_role.arn
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name        = local.pipeline_name
    Environment = var.environment
  })
}

### ---------------------------------------------------------------
### 로컬 변수
### ---------------------------------------------------------------

locals {
  ### 파이프라인 이름 - 명시적으로 지정하지 않으면 자동 생성
  pipeline_name = var.pipeline_name != "" ? var.pipeline_name : "${var.project_name}-${var.environment}-pipeline"
}

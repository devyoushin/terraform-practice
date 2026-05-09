# Terraform AWS CodePipeline 모듈

재사용 가능한 AWS CodePipeline CI/CD 파이프라인 Terraform 모듈입니다.
Source → Build → Deploy 3단계 파이프라인을 자동으로 구성하며, ECS Blue/Green, ECS Rolling, CloudFormation 등 다양한 배포 전략을 지원합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| 파이프라인 3단계 구성 | Source → Build → Deploy 자동화 |
| 소스 제공자 선택 | CodeCommit 또는 S3 (GitOps 패턴) |
| CodeBuild 프로젝트 | buildspec.yml 기반, Docker 빌드 지원 |
| 배포 전략 선택 | `ECS` (Rolling), `CodeDeployToECS` (Blue/Green), `CloudFormation` |
| 아티팩트 S3 버킷 | 버저닝 + AES256 암호화 + 퍼블릭 액세스 차단 자동 구성 |
| IAM 역할 자동 생성 | CodePipeline·CodeBuild 최소 권한 역할 자동 생성 |
| CloudWatch 로그 | 빌드 로그 자동 수집 (`/aws/codebuild/...`) |
| 로컬 빌드 캐시 | Docker 레이어·소스 캐시로 빌드 속도 향상 |

---

## 파이프라인 흐름

```
[Source Stage]            [Build Stage]           [Deploy Stage]
CodeCommit / S3  ──────▶  CodeBuild        ──────▶  ECS Rolling
                          (buildspec.yml)            ECS Blue/Green (CodeDeploy)
                                                     CloudFormation
```

### buildspec.yml 예시 (ECS 이미지 빌드)

```yaml
# buildspec.yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

  build:
    commands:
      - echo Build started on `date`
      - docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
      - docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

  post_build:
    commands:
      # ECS 직접 배포용 (deploy_provider = "ECS")
      - printf '[{"name":"%s","imageUri":"%s"}]' $CONTAINER_NAME $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| 소스 브랜치 | `develop` | `staging` | `main` |
| 빌드 컴퓨팅 타입 | `BUILD_GENERAL1_SMALL` | `BUILD_GENERAL1_SMALL` | `BUILD_GENERAL1_MEDIUM` |
| 배포 전략 | ECS Rolling | ECS Rolling | ECS Blue/Green 권장 |
| 아티팩트 버킷 강제 삭제 | `true` | `false` | `false` |
| 로그 보존 기간 | 7일 | 14일 | 90일 |
| `prevent_destroy` | 없음 | 없음 | 파이프라인 역할에 적용 권장 |

---

## 디렉토리 구조

```
codepipeline/
├── modules/codepipeline/  # 재사용 가능한 CodePipeline 모듈
│   ├── main.tf             # 파이프라인, CodeBuild, IAM, S3, CloudWatch 정의
│   ├── variables.tf        # 모듈 입력 변수
│   └── outputs.tf          # 모듈 출력값
├── envs/
│   ├── dev/                # 개발 환경
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/            # 스테이징 환경
│   └── prod/               # 운영 환경
├── Makefile                # 환경별 작업 자동화
├── .pre-commit-config.yaml
└── README.md
```

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `pipeline_name` | `string` | `""` | 파이프라인 이름 (빈 값이면 자동 생성) |
| `source_provider` | `string` | `"CodeCommit"` | 소스 제공자: `CodeCommit` 또는 `S3` |
| `repository_name` | `string` | 필수 | CodeCommit 저장소 이름 또는 S3 버킷 이름 |
| `branch_name` | `string` | `"main"` | 빌드할 브랜치 이름 |
| `build_compute_type` | `string` | `"BUILD_GENERAL1_SMALL"` | CodeBuild 컴퓨팅 타입 |
| `build_image` | `string` | `"aws/codebuild/standard:7.0"` | CodeBuild 빌드 이미지 |
| `buildspec_path` | `string` | `"buildspec.yml"` | buildspec 파일 경로 |
| `deploy_provider` | `string` | `"ECS"` | 배포 제공자: `ECS`, `CodeDeployToECS`, `CloudFormation` |
| `ecs_cluster_name` | `string` | `""` | ECS 클러스터 이름 (ECS 배포 시) |
| `ecs_service_name` | `string` | `""` | ECS 서비스 이름 (ECS 배포 시) |
| `deploy_app_name` | `string` | `""` | CodeDeploy 앱 이름 (Blue/Green 배포 시) |
| `deploy_group_name` | `string` | `""` | CodeDeploy 배포 그룹 이름 (Blue/Green 배포 시) |
| `log_retention_days` | `number` | `30` | CloudWatch 로그 보존 기간 (일) |
| `artifact_bucket_force_destroy` | `bool` | `false` | 아티팩트 버킷 강제 삭제 여부 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

---

## 모듈 출력값

> 현재 `outputs.tf` 파일 추가 필요 (미구현)

| 출력값 | 설명 |
|---|---|
| `pipeline_arn` | CodePipeline ARN |
| `pipeline_name` | CodePipeline 이름 |
| `codebuild_project_name` | CodeBuild 프로젝트 이름 |
| `artifact_bucket_name` | 아티팩트 S3 버킷 이름 |
| `pipeline_role_arn` | CodePipeline IAM 역할 ARN |
| `codebuild_role_arn` | CodeBuild IAM 역할 ARN |

---

## 사전 준비

### 1. 사전 요구사항 확인

```bash
# Terraform 버전 확인 (1.5.0 이상 필요)
terraform version

# AWS 자격증명 설정
aws configure

# CodeCommit 저장소가 있는지 확인 (source_provider = CodeCommit 사용 시)
aws codecommit list-repositories --region ap-northeast-2
```

### 2. IAM 권한 확인

| 서비스 | 필요 권한 |
|---|---|
| CodePipeline | `codepipeline:*` |
| CodeBuild | `codebuild:*` |
| CodeCommit | `codecommit:*` (소스 저장소 접근) |
| S3 | 아티팩트 버킷 생성 및 관리 |
| IAM | 역할 및 정책 생성 |
| ECS | 서비스 업데이트 권한 (ECS 배포 시) |
| CloudFormation | 스택 관리 (CloudFormation 배포 시) |

### 3. ECS 배포 사전 준비

ECS Rolling 배포(`deploy_provider = "ECS"`) 사용 시:

```bash
# ECS 클러스터 확인
aws ecs list-clusters --region ap-northeast-2

# ECS 서비스 확인
aws ecs list-services --cluster <CLUSTER_NAME> --region ap-northeast-2
```

ECS Blue/Green 배포(`deploy_provider = "CodeDeployToECS"`) 사용 시:
- CodeDeploy 애플리케이션 및 배포 그룹 사전 생성 필요
- `appspec.yaml` 및 `taskdef.json`을 buildspec 아티팩트에 포함해야 함

---

## 배포 방법

### Makefile 이용 (권장)

```bash
# 개발 환경 배포
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# 운영 환경 배포
make init ENV=prod
make plan ENV=prod
make apply ENV=prod

# 출력값 확인
make output ENV=prod
```

### 직접 Terraform 명령

```bash
cd envs/dev
cp ../../terraform.tfvars.example terraform.tfvars
vi terraform.tfvars   # 실제 값으로 수정

terraform init
terraform plan
terraform apply
```

---

## 사용 예시

### ECS Rolling 배포 (기본 패턴)

```hcl
module "codepipeline" {
  source = "../../modules/codepipeline"

  project_name = "my-project"
  environment  = "dev"

  source_provider = "CodeCommit"
  repository_name = "my-app-repo"
  branch_name     = "develop"

  deploy_provider  = "ECS"
  ecs_cluster_name = "dev-cluster"
  ecs_service_name = "my-app-service"

  artifact_bucket_force_destroy = true  # dev 환경만
  log_retention_days            = 7
}
```

### ECS Blue/Green 배포 (prod 권장)

```hcl
module "codepipeline" {
  source = "../../modules/codepipeline"

  project_name = "my-project"
  environment  = "prod"

  source_provider = "CodeCommit"
  repository_name = "my-app-repo"
  branch_name     = "main"

  build_compute_type = "BUILD_GENERAL1_MEDIUM"  # 빌드 속도 향상

  deploy_provider  = "CodeDeployToECS"
  deploy_app_name  = "my-app-codedeploy"
  deploy_group_name = "my-app-deployment-group"

  log_retention_days = 90
}
```

### GitHub Actions와 통합 (S3 소스 패턴)

GitHub Actions → S3 → CodePipeline 패턴을 사용하면 GitHub와 연동할 수 있습니다.

```yaml
# .github/workflows/deploy.yml
- name: Upload source to S3
  run: |
    zip -r source.zip . -x '*.git*'
    aws s3 cp source.zip s3://my-project-dev-source/main/source.zip
```

```hcl
module "codepipeline" {
  source_provider = "S3"
  repository_name = "my-project-dev-source"   # S3 버킷 이름
  branch_name     = "main"                     # S3 Object Key 접두사
}
```

---

## 파이프라인 실행 확인

```bash
# 파이프라인 실행 내역 확인
aws codepipeline list-pipeline-executions \
  --pipeline-name my-project-dev-pipeline \
  --region ap-northeast-2

# 현재 파이프라인 상태 확인
aws codepipeline get-pipeline-state \
  --name my-project-dev-pipeline \
  --region ap-northeast-2

# 수동으로 파이프라인 실행
aws codepipeline start-pipeline-execution \
  --name my-project-dev-pipeline \
  --region ap-northeast-2

# 빌드 로그 확인
aws logs tail /aws/codebuild/my-project-dev-build \
  --follow \
  --region ap-northeast-2
```

---

## 트러블슈팅

### 파이프라인 소스 단계 실패

```bash
# CodeCommit 브랜치 존재 여부 확인
aws codecommit list-branches \
  --repository-name <REPO_NAME> \
  --region ap-northeast-2

# S3 소스 버킷 오브젝트 확인
aws s3 ls s3://<BUCKET_NAME>/<BRANCH_NAME>/
```

### 빌드 단계 실패 — IAM 권한 부족

CodeBuild 역할에 ECR 푸시 권한이 없는 경우 발생합니다.

```bash
# CodeBuild 역할에 ECR 권한 추가 필요
aws iam attach-role-policy \
  --role-name my-project-dev-codebuild-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### 빌드 단계 실패 — Docker 권한 오류

buildspec.yml에서 Docker 명령 실행 시 `privileged_mode = true` 설정을 확인합니다.
이 모듈의 `aws_codebuild_project.this`에는 `privileged_mode = true`가 기본 설정되어 있습니다.

### ECS 배포 단계 실패

```bash
# ECS 서비스 이벤트 확인
aws ecs describe-services \
  --cluster <CLUSTER_NAME> \
  --services <SERVICE_NAME> \
  --query 'services[0].events[:5]' \
  --region ap-northeast-2

# 태스크 정의 확인 (imagedefinitions.json이 올바른지)
aws ecs describe-task-definition \
  --task-definition <TASK_DEF_ARN> \
  --region ap-northeast-2
```

---

## 현재 모듈 구현 상태

| 파일 | 상태 |
|---|---|
| `modules/codepipeline/main.tf` | ✅ 완료 |
| `modules/codepipeline/variables.tf` | ❌ 미구현 |
| `modules/codepipeline/outputs.tf` | ❌ 미구현 |
| `envs/dev/` | ❌ 미구현 |
| `envs/staging/` | ❌ 미구현 |
| `envs/prod/` | ❌ 미구현 |
| `Makefile` | ❌ 미구현 |
| `.pre-commit-config.yaml` | ❌ 미구현 |

---

## 요구사항

| 항목 | 버전 |
|---|---|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 |

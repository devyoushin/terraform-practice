# terraform-iam

AWS IAM 리소스를 패턴별로 관리하는 Terraform 프로젝트입니다.
3가지 핵심 IAM 패턴을 모듈로 제공하며, 환경(dev/prod)별로 독립 관리합니다.

---

## IAM 패턴 소개

### 1. ec2-role — EC2 인스턴스 IAM Role
EC2 인스턴스에 부착하는 IAM Role과 Instance Profile을 생성합니다.

- **SSM Session Manager**: SSH 키 없이 AWS 콘솔/CLI로 원격 접속 (포트 22 불필요)
- **CloudWatch Agent**: 메트릭 및 로그를 CloudWatch로 전송
- **S3 접근** (선택): 특정 버킷에 대한 GetObject/PutObject/ListBucket 권한

### 2. cicd-role — GitHub Actions OIDC CI/CD Role
GitHub Actions 워크플로우가 AWS에 접근할 수 있도록 OIDC 방식의 Role을 생성합니다.

- **장기 자격증명 불필요**: Access Key/Secret Key를 GitHub Secrets에 저장하지 않아도 됨
- **OIDC 토큰 기반 인증**: GitHub이 발급한 단기 토큰으로 AssumeRoleWithWebIdentity
- **세밀한 접근 제어**: 특정 Org/Repo/브랜치에만 허용 가능

### 3. eks-irsa — EKS IRSA (IAM Roles for Service Accounts)
EKS Pod에 IAM 권한을 부여하는 IRSA 패턴을 구현합니다.

- **Pod 레벨 권한 분리**: Node IAM Role이 아닌 Pod별 개별 IAM Role 사용
- **최소 권한 원칙**: 특정 Namespace/ServiceAccount 조합에만 AssumeRole 허용
- **Node 인스턴스 Role 오염 방지**: 워크로드별 독립적인 권한 관리

---

## 디렉토리 구조

```
terraform-iam/
├── modules/
│   ├── ec2-role/           # EC2 인스턴스 IAM Role
│   ├── cicd-role/          # GitHub Actions OIDC Role
│   └── eks-irsa/           # EKS IRSA 패턴
├── envs/
│   ├── dev/                # DEV 환경
│   └── prod/               # PROD 환경
├── Makefile
├── .pre-commit-config.yaml
└── .gitignore
```

---

## 모듈별 변수 및 출력 참조

### modules/ec2-role

#### 변수

| 변수명 | 타입 | 기본값 | 설명 |
|--------|------|--------|------|
| `project_name` | `string` | 필수 | 프로젝트 이름 (리소스 네이밍) |
| `environment` | `string` | 필수 | 배포 환경 (dev, staging, prod) |
| `s3_bucket_arns` | `list(string)` | `[]` | 접근 허용할 S3 버킷 ARN 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 |

#### 출력값

| 출력명 | 설명 |
|--------|------|
| `role_arn` | IAM Role ARN |
| `role_name` | IAM Role 이름 |
| `instance_profile_arn` | Instance Profile ARN |
| `instance_profile_name` | Instance Profile 이름 |

---

### modules/cicd-role

#### 변수

| 변수명 | 타입 | 기본값 | 설명 |
|--------|------|--------|------|
| `role_name` | `string` | 필수 | IAM Role 이름 |
| `github_org` | `string` | 필수 | GitHub 조직/유저명 |
| `github_repo` | `string` | 필수 | 레포지토리 이름 (`*` 가능) |
| `create_oidc_provider` | `bool` | `true` | OIDC Provider 신규 생성 여부 |
| `existing_oidc_provider_arn` | `string` | `null` | 기존 OIDC Provider ARN |
| `policy_arns` | `list(string)` | `["ReadOnlyAccess"]` | 연결할 정책 ARN 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 |

#### 출력값

| 출력명 | 설명 |
|--------|------|
| `role_arn` | IAM Role ARN |
| `role_name` | IAM Role 이름 |
| `oidc_provider_arn` | OIDC Provider ARN |

---

### modules/eks-irsa

#### 변수

| 변수명 | 타입 | 기본값 | 설명 |
|--------|------|--------|------|
| `role_name` | `string` | 필수 | IAM Role 이름 |
| `oidc_provider_arn` | `string` | 필수 | EKS 클러스터 OIDC Provider ARN |
| `namespace` | `string` | 필수 | Kubernetes 네임스페이스 |
| `service_account_name` | `string` | 필수 | ServiceAccount 이름 |
| `policy_arns` | `list(string)` | `[]` | 연결할 정책 ARN 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 |

#### 출력값

| 출력명 | 설명 |
|--------|------|
| `role_arn` | IRSA IAM Role ARN |
| `role_name` | IRSA IAM Role 이름 |

---

## 사용 예시

### EC2 Role 생성

```hcl
module "ec2_role" {
  source = "../../modules/ec2-role"

  project_name = "my-project"
  environment  = "dev"

  # S3 접근 권한 추가 (선택)
  s3_bucket_arns = [
    "arn:aws:s3:::my-bucket",
    "arn:aws:s3:::my-bucket/*",
  ]

  common_tags = {
    Project     = "my-project"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### EC2 인스턴스에 Instance Profile 연결

`terraform-ec2` 등 EC2 모듈에서 아래와 같이 참조합니다.

```hcl
resource "aws_instance" "app" {
  ami                  = "ami-xxxxxxxx"
  instance_type        = "t3.micro"
  iam_instance_profile = module.ec2_role.instance_profile_name
}
```

---

### GitHub Actions CI/CD Role 생성

```hcl
module "cicd_role" {
  source = "../../modules/cicd-role"

  role_name   = "my-project-dev-cicd"
  github_org  = "my-github-org"
  github_repo = "my-repo"

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECR-FullAccess",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]
}
```

### GitHub Actions 워크플로우에서 OIDC Role 사용

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  id-token: write   # OIDC 토큰 발급 필수
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: AWS 자격증명 설정 (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ap-northeast-2

      - name: ECR 로그인
        run: aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY
```

> `AWS_ROLE_ARN` 시크릿에 `module.cicd_role.role_arn` 출력값을 저장합니다.

---

### EKS IRSA Role 생성

```hcl
module "app_irsa" {
  source = "../../modules/eks-irsa"

  role_name            = "my-project-dev-app-role"
  oidc_provider_arn    = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/XXXXX"
  namespace            = "default"
  service_account_name = "my-app"

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]
}
```

### Kubernetes ServiceAccount에 Role 연결

```yaml
# kubernetes/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-project-dev-app-role
```

---

## 시작 방법

```bash
# 1. 환경 초기화
make init ENV=dev

# 2. 변경 계획 확인
make plan ENV=dev

# 3. 적용
make apply ENV=dev

# 4. 출력값 확인
make output ENV=dev
```

---

## 요구사항

| 도구 | 최소 버전 | 설치 방법 |
|------|-----------|-----------|
| Terraform | >= 1.5.0 | [공식 문서](https://developer.hashicorp.com/terraform/install) |
| AWS Provider | ~> 5.0 | Terraform이 자동 설치 |
| AWS CLI | >= 2.0 | `brew install awscli` |
| tflint | 최신 | `brew install tflint` |
| terraform-docs | 최신 | `brew install terraform-docs` |
| gitleaks | 최신 | `brew install gitleaks` |
| pre-commit | 최신 | `pip install pre-commit` |

### Pre-commit 설치

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files  # 전체 파일 검사
```

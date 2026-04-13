# Terraform AWS 인프라 실습 저장소

프로덕션 수준의 Terraform 모듈 모음으로, VPC부터 EKS, RDS, CloudFront까지 AWS 전체 스택을 다룹니다. 각 모듈은 dev / staging / prod 세 가지 환경에 걸쳐 실무 운영 패턴을 포함합니다.

---

## 모듈 디렉토리

| 모듈 | 설명 | 상태 |
|------|------|------|
| [vpc](./vpc/) | VPC, 서브넷, NAT Gateway, VPC Endpoints, Flow Logs | ✅ 완료 |
| [ec2](./ec2/) | EC2 인스턴스, EBS, Security Groups, IAM 프로파일 | ✅ 완료 |
| [alb](./alb/) | Application Load Balancer, HTTPS/ACM, 액세스 로그 | ✅ 완료 |
| [rds](./rds/) | RDS MySQL 8.0, Multi-AZ, 백업, Performance Insights | ✅ 완료 |
| [s3](./s3/) | S3 버킷, 버전 관리, 수명 주기, 암호화 | ✅ 완료 |
| [cloudfront](./cloudfront/) | CloudFront CDN, OAC, WAF 연동, 커스텀 도메인 | ✅ 완료 |
| [waf](./waf/) | WAF v2, IP 차단, 레이트 리밋, 관리형 규칙 | ✅ 완료 |
| [iam](./iam/) | IAM 역할: EC2, GitHub OIDC (CI/CD), EKS IRSA | ✅ 완료 |
| [kms](./kms/) | KMS 키, 자동 교체, 멀티 리전 | ✅ 완료 |
| [secrets-manager](./secrets-manager/) | Secrets Manager, KMS 암호화, 자동 교체 | ✅ 완료 |
| [eks](./eks/) | EKS 클러스터, 관리형 노드 그룹, Karpenter, IRSA | ✅ 완료 |
| [ecr](./ecr/) | ECR, 이미지 스캔, 수명 주기 정책 | ✅ 완료 |
| [elasticache](./elasticache/) | ElastiCache Redis, Multi-AZ, 암호화, 스냅샷 | ✅ 완료 |
| [dynamodb](./dynamodb/) | DynamoDB, OnDemand/Provisioned, GSI, PITR | ✅ 완료 |
| [cloudwatch](./cloudwatch/) | CloudWatch Logs, 알람, 대시보드, SNS | ✅ 완료 |
| [bastion](./bastion/) | Bastion 호스트, SSM Session Manager, SSH | ✅ 완료 |
| [tgw](./tgw/) | Transit Gateway, 허브-앤-스포크, VPN, RAM 공유 | ✅ 완료 |
| [route53](./route53/) | 호스팅 존, DNS 레코드, 헬스 체크, 페일오버 | ⚠️ dev 완료, staging/prod 미구현 |
| [sqs-sns](./sqs-sns/) | SQS 큐, SNS 토픽, DLQ, 구독 | ⚠️ dev 완료, staging/prod 미구현 |
| [backup](./backup/) | AWS Backup, 볼트, 계획, 보존 기간 관리 | ⚠️ dev 완료, staging/prod 미구현 |
| [guardduty](./guardduty/) | GuardDuty, 위협 감지, SNS 알림, 심각도 필터 | ⚠️ dev 완료, staging/prod 미구현 |
| [codepipeline](./codepipeline/) | CodePipeline, CodeBuild, ECS 배포 (Rolling/Blue-Green) | ⚠️ 모듈 부분 완료, envs 미구현 |

---

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                          엣지 레이어                             │
│          Route53 → CloudFront (WAF) → ALB (WAF)                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                        컴퓨트 레이어                             │
│               EC2 / EKS (Karpenter) / Bastion                   │
└──────┬────────────────────────────────┬──────────────────────────┘
       │                                │
┌──────▼──────────┐          ┌──────────▼──────────┐
│   데이터 레이어  │          │    메시징 레이어     │
│  RDS / DynamoDB │          │    SQS / SNS         │
│  ElastiCache    │          └─────────────────────┘
│  S3 / Backup    │
└─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    보안 및 자격 증명 레이어                      │
│         IAM / KMS / Secrets Manager / WAF / GuardDuty           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        네트워크 기반                             │
│              VPC / TGW (멀티 계정) / Route53                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    옵저버빌리티 및 CI/CD                         │
│          CloudWatch / ECR / CodePipeline / CodeBuild             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 디렉토리 구조

모든 모듈은 동일한 3-환경 구조를 따릅니다.

```
모듈명/
├── modules/
│   └── 모듈명/
│       ├── main.tf          # 리소스 정의
│       ├── variables.tf     # 입력 변수
│       └── outputs.tf       # 다른 모듈에서 참조하는 출력값
├── envs/
│   ├── dev/                 # 저비용, 빠른 반복, 언제든 삭제 가능
│   ├── staging/             # 프로덕션과 유사, 통합 테스트용
│   └── prod/                # 완전한 가용성, 모든 보호 기능 활성화
├── Makefile                 # init / plan / apply / destroy 단축 명령
├── .pre-commit-config.yaml
├── terraform.tfvars.example
└── README.md
```

---

## 사전 요구사항

### 1. Terraform

**설치**
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

**설치 확인**
```bash
terraform version
# Terraform v1.6.0 이상 필요
```

---

### 2. AWS CLI

AWS API 호출 및 인증에 사용됩니다.

**설치**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

**자격증명 설정**
```bash
aws configure
# AWS Access Key ID:     ← IAM 사용자 Access Key 입력
# AWS Secret Access Key: ← IAM 사용자 Secret Key 입력
# Default region name:   ap-northeast-2
# Default output format: json
```

**설치 확인**
```bash
aws --version
aws sts get-caller-identity
```

---

### 3. 선택적 도구 (EKS 모듈 사용 시)

| 도구 | 용도 | 설치 |
|------|------|------|
| kubectl | Kubernetes 클러스터 제어 | `brew install kubectl` |
| helm >= 3.0 | Karpenter Helm 차트 설치 | `brew install helm` |

---

### 4. IAM 권한 확인

Terraform을 실행하는 IAM 사용자 또는 역할에 아래 권한이 필요합니다.

| 서비스 | 필요 권한 |
|--------|-----------|
| VPC / EC2 | VPC, 서브넷, NAT Gateway, 보안 그룹 생성/삭제 |
| EKS | 클러스터 생성/삭제, 노드 그룹 관리, 액세스 항목 관리 |
| IAM | 역할, 정책, 인스턴스 프로파일 생성/삭제 |
| RDS / ElastiCache / DynamoDB | DB 인스턴스 생성/삭제, 파라미터 그룹 관리 |
| S3 | 버킷 생성/삭제, 정책 설정 |
| KMS | 키 생성/삭제, 키 정책 관리 |
| Route53 | 호스팅 존, 레코드, 헬스 체크 관리 |
| SQS / SNS | 큐/토픽 생성/삭제, 정책 설정 |

> 테스트 환경에서는 `AdministratorAccess` 정책을 사용할 수 있습니다.

---

## 빠른 시작

```bash
# 1. 원하는 모듈 환경 디렉토리로 이동
cd vpc/envs/dev

# 2. 변수 파일 준비
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars   # 실제 값으로 수정

# 3. 백엔드와 함께 초기화
terraform init \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="key=dev/vpc/terraform.tfstate" \
  -backend-config="region=ap-northeast-2"

# 4. 플랜 확인 후 적용
terraform plan
terraform apply

# 또는 Makefile 단축 명령 사용
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

---

## 원격 백엔드 설정

### 1. 백엔드 리소스 먼저 생성 (최초 1회)

```bash
# S3 버킷 생성 (상태 파일 저장소)
aws s3 mb s3://my-company-terraform-state --region ap-northeast-2
aws s3api put-bucket-versioning \
  --bucket my-company-terraform-state \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket my-company-terraform-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'

# DynamoDB 테이블 생성 (상태 잠금용)
aws dynamodb create-table \
  --table-name my-company-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2
```

### 2. 환경별 backend.tf 설정

```hcl
# envs/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "prod/vpc/terraform.tfstate"  # 규칙: {env}/{module}
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "my-company-terraform-locks"
  }
}
```

### 3. 상태 키 명명 규칙

```
{계정-별칭}/{환경}/{모듈}/terraform.tfstate

예시:
  production/prod/vpc/terraform.tfstate
  production/prod/eks/terraform.tfstate
  production/prod/rds/terraform.tfstate
  staging/staging/vpc/terraform.tfstate
  dev/dev/vpc/terraform.tfstate
```

### 4. 다른 모듈의 상태 참조 (Remote State)

```hcl
# eks/envs/prod/main.tf — VPC ID를 하드코딩 없이 읽기
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-company-terraform-state"
    key    = "production/prod/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "eks" {
  source     = "../../modules/eks"
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}
```

---

## 모듈 간 의존성 및 배포 순서

모듈 간 의존성이 있는 경우, 아래 권장 배포 순서를 따르세요.

```
1. vpc           ← 모든 모듈의 기반 (서브넷, NAT Gateway)
2. iam           ← 서비스 역할 및 OIDC Provider 생성
3. kms           ← 암호화 키 생성 (RDS/S3/SQS 암호화 시 먼저 배포)
4. route53       ← ACM 인증서 발급 전 호스팅 존 필요
5. s3            ← CloudFront Origin, 로그 버킷
6. ecr           ← EKS 배포 전 이미지 저장소 생성
7. eks           ← vpc, iam, ecr 이후 배포
8. rds           ← vpc, kms, secrets-manager 이후 배포
9. elasticache   ← vpc 이후 배포
10. alb          ← vpc, route53, ACM 인증서 이후 배포
11. cloudfront   ← alb, s3, waf, route53 이후 배포
12. backup       ← 보호할 리소스(rds, dynamodb 등) 생성 이후 배포
13. guardduty    ← 언제든 독립적으로 배포 가능
14. codepipeline ← ecr, ecs 클러스터 이후 배포
```

### Remote State로 모듈 간 값 전달

```hcl
# eks/envs/prod/main.tf
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-company-terraform-state"
    key    = "prod/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "eks" {
  source     = "../../modules/eks"
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}
```

---

## 실무 Terraform 전략

### 1. 상태 파일 격리

**원칙: 모듈별, 환경별 상태 파일 분리. 하나의 거대한 상태 파일은 절대 사용하지 않습니다.**

```
❌ 잘못된 방법: 단일 상태 파일
  terraform/terraform.tfstate  ← 모든 것이 한 파일에

✅ 올바른 방법: 격리된 상태 파일
  prod/vpc/terraform.tfstate
  prod/rds/terraform.tfstate
  prod/eks/terraform.tfstate
```

격리의 장점:
- EKS의 `apply` 실패가 RDS 작업을 잠그지 않음
- 실수의 영향 범위 최소화
- 플랜/어플라이 속도 향상 (관련 리소스만 갱신)
- 팀별 상태 파일 소유권 분리 가능

---

### 2. 시크릿 및 tfvars 관리

**절대 시크릿을 Git에 커밋하지 마세요.** 이 저장소의 `.gitignore`는 `*.tfvars`를 제외합니다 (`*.tfvars.example` 제외).

**패턴 1: terraform.tfvars (소규모 팀)**

```hcl
# terraform.tfvars.example — 이 파일은 커밋
db_password   = "CHANGE_ME"
slack_webhook = "CHANGE_ME"

# terraform.tfvars — git 제외, 로컬에서 직접 입력하거나 CI에서 주입
db_password   = "실제-비밀번호"
slack_webhook = "https://hooks.slack.com/..."
```

**패턴 2: SSM Parameter Store (CI/CD 권장)**

```bash
aws ssm put-parameter \
  --name "/prod/rds/password" \
  --value "actual-password" \
  --type "SecureString"
```

```hcl
data "aws_ssm_parameter" "db_password" {
  name            = "/prod/rds/password"
  with_decryption = true
}
```

**패턴 3: CI/CD 환경변수 주입**

```yaml
# GitHub Actions
- name: Terraform Apply
  env:
    TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
  run: terraform apply -auto-approve
```

---

### 3. 환경 프로모션 워크플로우

```
개발자 → dev → staging → prod

1. envs/dev/ 에서 변경
2. dev에서 terraform plan, 확인
3. dev에서 terraform apply, 테스트
4. 확인된 변경 내용을 envs/staging/으로 복사
5. staging 변경에 대한 PR 리뷰
6. staging에서 terraform apply, 통합 테스트 실행
7. prod 프로모션을 위해 main으로 PR
8. 동료 리뷰 (prod 필수)
9. prod에서 terraform plan — 플랜 출력 신중히 검토
10. 유지 관리 윈도우 동안 prod에서 terraform apply
```

**프로덕션 황금 규칙:** 항상 `terraform plan`을 실행하고 출력을 저장한 후 적용하세요.

```bash
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt  # 사람이 읽을 수 있는 형태로 검토
terraform apply tfplan.binary                        # 검토한 플랜 그대로 적용
```

---

### 4. 파괴적 변경 방지

```hcl
resource "aws_db_instance" "main" {
  lifecycle {
    prevent_destroy       = true          # terraform destroy 및 실수로 인한 삭제 차단
    ignore_changes        = [password]    # 외부에서 교체된 패스워드 드리프트 감지 안 함
    create_before_destroy = true          # 지원 리소스의 무중단 교체
  }
}
```

```bash
# CI 파이프라인 — 리소스 삭제를 포함한 PR 차단
terraform plan -detailed-exitcode 2>&1 | tee tfplan.txt
if grep -q "will be destroyed" tfplan.txt; then
  echo "오류: 플랜에 리소스 삭제 포함. 수동 승인 필요."
  exit 1
fi
```

---

### 5. 상태 작업: import, mv, rm

```bash
# 기존 수동 생성 리소스를 Terraform 관리로 가져오기
terraform import aws_db_instance.main db-instance-identifier

# Terraform 1.5+ 권장 방법
import {
  to = aws_db_instance.main
  id = "my-rds-identifier"
}

# 재생성 없이 리소스 이름 변경
terraform state mv aws_s3_bucket.old_name aws_s3_bucket.new_name

# 삭제하지 않고 상태에서 제거
terraform state rm aws_instance.legacy_app

# 상태 조회
terraform state list
terraform state show aws_db_instance.main
```

---

### 6. CI/CD 연동 (GitHub Actions)

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  pull_request:
    paths: ['envs/staging/**', 'modules/**']
  push:
    branches: [main]
    paths: ['envs/prod/**']

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # OIDC 필수
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - name: AWS 자격증명 설정 (OIDC — 장기 키 불필요)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-actions-terraform
          aws-region: ap-northeast-2

      - name: Terraform 설정
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.6"

      - name: Terraform Init
        run: terraform init
        working-directory: envs/staging

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        working-directory: envs/staging

      - name: PR에 플랜 결과 게시
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan 📋
            \`\`\`\n${{ steps.plan.outputs.stdout }}\`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
```

---

## 환경별 비교

| 항목 | dev | staging | prod |
|------|-----|---------|------|
| 비용 | 최소 | 중간 | 전체 |
| 가용성 | 단일 AZ | 단일 AZ | Multi-AZ |
| 백업 | 최소 | 짧은 보존 | 긴 보존 |
| 암호화 | 선택적 | 권장 | 필수 |
| 삭제 보호 | 비활성 | 비활성 | 활성 |
| 모니터링 | 기본 | 표준 | 전체 + 알람 |
| `force_destroy` | `true` | `false` | `false` |

---

## Makefile 주요 타겟

모든 모듈에는 편의를 위한 Makefile이 포함됩니다.

```bash
make init ENV=dev        # 백엔드 설정과 함께 terraform init
make plan ENV=staging    # terraform plan
make apply ENV=prod      # terraform apply (확인 프롬프트 포함)
make destroy ENV=dev     # terraform destroy (확인 프롬프트 포함)
make fmt                 # terraform fmt -recursive
make validate            # terraform validate
make output ENV=dev      # terraform output
```

---

## 보안 체크리스트

프로덕션 적용 전 확인:

- [ ] `terraform.tfvars`가 Git에 **커밋되지 않음**
- [ ] S3 상태 버킷에 버전 관리 및 암호화 활성화
- [ ] S3 상태 버킷이 모든 퍼블릭 액세스 차단
- [ ] DynamoDB 잠금 테이블이 존재하고 `backend.tf`에서 참조됨
- [ ] IAM 역할이 최소 권한 원칙 준수 (필요 없는 `*` 액션 없음)
- [ ] 모든 프로덕션 데이터베이스에 `deletion_protection = true`
- [ ] KMS 키에 수명 주기의 `prevent_destroy = true`
- [ ] 상태 유지 리소스(RDS, 데이터가 있는 S3 등)에 `prevent_destroy = true`
- [ ] pre-commit 훅 통과 (`terraform fmt`, `terraform validate`, `tflint`)
- [ ] 적용 전 플랜 출력 검토 완료
- [ ] 프로덕션 적용은 유지 관리 윈도우 동안 진행

---

## pre-commit 훅

각 모듈에는 `.pre-commit-config.yaml`이 포함됩니다.

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

매 커밋 시 실행되는 검사:
- `terraform fmt` — 일관된 포맷 적용
- `terraform validate` — 구문 및 로직 검증
- `tflint` — 일반적인 실수 린팅
- `checkov` — 보안 정책 검사 (선택적)

---

## 트러블슈팅

### terraform init 실패 — provider 다운로드 오류

```bash
# provider 캐시 초기화 후 재시도
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### 상태 파일 잠금 오류

```bash
# 다른 프로세스가 잠금을 보유한 경우 (강제 해제는 신중히)
terraform force-unlock <LOCK_ID>
```

### 리소스 드리프트 감지

```bash
# Terraform 상태와 실제 AWS 리소스 비교
terraform plan -refresh-only

# 드리프트 수용 (Terraform 상태를 실제 상태와 동기화)
terraform apply -refresh-only
```

### 백엔드 마이그레이션 (로컬 → S3)

```bash
# backend.tf 파일 작성 후 실행
terraform init -migrate-state
```

---

## 모듈 구현 상태

| 모듈 | modules | envs dev | envs staging/prod | Makefile | pre-commit |
|------|---------|----------|-------------------|----------|------------|
| vpc, ec2, alb, rds, s3 | ✅ | ✅ | ✅ | ✅ | ✅ |
| cloudfront, waf, iam, kms, secrets-manager | ✅ | ✅ | ✅ | ✅ | ✅ |
| eks, ecr, elasticache, dynamodb | ✅ | ✅ | ✅ | ✅ | ✅ |
| cloudwatch, bastion, tgw | ✅ | ✅ | ✅ | ✅ | ✅ |
| route53, sqs-sns | ✅ | ✅ | ❌ | ✅ | ✅ |
| backup, guardduty | ✅ | ✅ | ❌ | ❌ | ❌ |
| codepipeline | ⚠️ 부분 | ❌ | ❌ | ❌ | ❌ |

---

## 요구사항

| 항목 | 버전 |
|------|------|
| Terraform | >= 1.6.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 |
| kubectl | 최신 안정 버전 (EKS 사용 시) |
| helm | >= 3.0 (EKS 사용 시) |
| pre-commit | >= 3.0 (선택, 코드 품질 관리) |
| TFLint | >= 0.50 (선택, 정적 분석) |

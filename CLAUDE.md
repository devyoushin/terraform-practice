# CLAUDE.md — terraform-practice 작업 가이드

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 규칙 및 컨텍스트 문서입니다.

---

## 저장소 개요

AWS 인프라를 Terraform으로 관리하는 실무 수준의 모듈 모음입니다.

두 가지 패턴을 모두 포함합니다:
- **레거시 패턴**: `<module>/modules/` + `<module>/envs/` 분리 (각 모듈 디렉토리 내부)
- **Terragrunt 패턴**: `dev/` + `prod/` 환경 디렉토리 + 루트 `terragrunt.hcl` (권장)

---

## 디렉토리 구조

```
terraform-practice/
├── CLAUDE.md                  # 이 파일 (자동 로드)
├── terragrunt.hcl             # 루트 Terragrunt 설정 (remote_state, provider 자동 생성)
├── _envs/                     # 환경별 변수 참조 문서
│   ├── dev.hcl                # dev 공통 변수 (참조용)
│   └── prod.hcl               # prod 공통 변수 (참조용)
├── bootstrap/                 # Remote State 인프라 (S3 + DynamoDB) — 최초 1회 실행
│   ├── main.tf
│   └── outputs.tf
│
├── dev/                       # [Terragrunt] DEV 환경 모듈 호출
│   ├── env.hcl                # environment = "dev" 선언
│   ├── vpc/terragrunt.hcl
│   ├── kms/{rds,s3,eks}/terragrunt.hcl
│   ├── iam/terragrunt.hcl
│   ├── s3/{assets,logs}/terragrunt.hcl
│   ├── secrets-manager/{rds,app-config}/terragrunt.hcl
│   ├── ec2/terragrunt.hcl
│   ├── alb/terragrunt.hcl
│   ├── rds/terragrunt.hcl
│   ├── elasticache/terragrunt.hcl
│   ├── dynamodb/{sessions,tfstate-lock}/terragrunt.hcl
│   ├── eks/terragrunt.hcl
│   ├── ecr/{app,api}/terragrunt.hcl
│   ├── cloudfront/terragrunt.hcl
│   ├── waf/terragrunt.hcl
│   ├── cloudwatch/terragrunt.hcl
│   ├── bastion/terragrunt.hcl
│   ├── route53/terragrunt.hcl
│   ├── sqs-sns/terragrunt.hcl
│   ├── backup/terragrunt.hcl
│   ├── guardduty/terragrunt.hcl
│   └── codepipeline/terragrunt.hcl
│
├── prod/                      # [Terragrunt] PROD 환경 모듈 호출 (dev + s3/backup 추가)
│   └── ... (dev와 동일 구조)
│
├── .claude/
│   ├── settings.json          # 권한 설정 (apply/destroy 차단) + PostToolUse 훅
│   └── commands/              # 커스텀 슬래시 명령어
├── agents/                    # 전문 에이전트 정의
├── templates/                 # 문서 템플릿
├── rules/                     # Claude 작성 규칙
│
└── <module>/                  # [레거시] 각 AWS 서비스 모듈
    ├── modules/<module>/      # 재사용 가능한 리소스 정의 (Terragrunt에서도 참조)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── envs/                  # 레거시: 직접 terraform apply 용
    │   ├── dev/
    │   └── prod/
    ├── Makefile
    ├── .pre-commit-config.yaml
    └── README.md
```

---

## 커스텀 슬래시 명령어

| 명령어 | 설명 | 사용 예시 |
|--------|------|---------|
| `/new-doc` | 새 모듈 README 생성 | `/new-doc opensearch` |
| `/new-runbook` | 새 런북 생성 | `/new-runbook RDS 스냅샷 복구` |
| `/review-doc` | 코드/문서 검토 | `/review-doc eks/modules/eks/main.tf` |
| `/add-troubleshooting` | 트러블슈팅 케이스 추가 | `/add-troubleshooting EKS 노드 드레인 타임아웃` |
| `/search-kb` | 지식베이스 검색 | `/search-kb Karpenter 배포 순서` |

---

## 언어 및 스타일 규칙

- **문서(README, CLAUDE.md)는 반드시 한국어로 작성**
- **코드 주석도 한국어** — 모듈 상단에 `### === ... ===` 블록, 섹션 구분에 `### --- ... ---` 사용
- README 스타일 기준: `eks/README.md` 참고

### 코드 주석 패턴

```hcl
### =============================================================================
### modules/example/main.tf
### 리소스 설명
### =============================================================================

### ---------------------------------------------------------------
### 섹션 제목
### ---------------------------------------------------------------
resource "aws_example" "this" {
  # 한국어 인라인 주석
}
```

---

## 환경별 설정 원칙

| 항목 | dev | prod |
|------|-----|------|
| `force_destroy` | `true` | `false` |
| `deletion_protection` | `false` | `true` |
| Multi-AZ / 복제 | 단일 AZ (2 AZ) | Multi-AZ (3 AZ) |
| KMS 암호화 | 선택적 | **필수** |
| CloudWatch 알람 | 비활성화 | 활성화 |
| 백업/보존 기간 | 최단 | 최장 |
| `prevent_destroy` | 없음 | **필수** |
| VPC CIDR | `10.10.0.0/16` | `10.0.0.0/16` |

---

## 모듈 변수 패턴

```hcl
variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment 변수는 dev, prod 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}
```

### 리소스 명명 규칙

```
{project_name}-{environment}-{resource_type}
예: my-project-prod-rds-instance
```

---

## Terragrunt 사용 방법

### 시작 전 준비 (최초 1회)

```bash
# 1. Remote State 인프라 생성 (S3 + DynamoDB)
cd bootstrap
terraform init && terraform apply

# 2. Terragrunt 설치
brew install terragrunt
```

### 단일 모듈 실행

```bash
cd dev/vpc
terragrunt init
terragrunt plan
terragrunt apply

# 출력값 확인
terragrunt output
```

### 환경 전체 실행 (의존성 순서 자동 처리)

```bash
# DEV 전체 plan (의존성 그래프 자동 계산)
terragrunt run-all plan --terragrunt-working-dir dev/

# DEV 전체 apply
terragrunt run-all apply --terragrunt-working-dir dev/

# 특정 모듈만 (+ 모든 의존성 포함)
terragrunt run-all apply --terragrunt-working-dir dev/rds/
```

### 모듈 간 의존성 구조

```
vpc ──┬──→ ec2
      ├──→ alb ──→ route53
      ├──→ rds (+ kms/rds)
      ├──→ elasticache
      ├──→ bastion
      └──→ eks (+ kms/eks)

kms/s3 ──┬──→ s3/* (prod)
          ├──→ secrets-manager/*
          ├──→ dynamodb/* (prod)
          ├──→ sqs-sns (prod)
          └──→ backup

ecr/app ──→ codepipeline
cloudwatch ──→ route53 / sqs-sns / guardduty (prod)
```

### dependency mock_outputs 활용

Terragrunt의 `mock_outputs`를 사용하면 의존 모듈이 없어도 `plan`/`validate` 가능:

```bash
# 실제 VPC 없이도 RDS plan 실행 가능 (mock VPC ID 사용)
cd dev/rds && terragrunt plan
```

---

## Makefile 표준 타겟 (레거시)

```makefile
make init ENV=dev        # terraform init
make plan ENV=dev        # terraform plan
make apply ENV=prod      # terraform apply (Claude는 실행 불가 — 사람이 직접)
make destroy ENV=dev     # terraform destroy (Claude는 실행 불가)
make fmt                 # terraform fmt -recursive
make validate            # terraform validate
make output ENV=dev      # terraform output
```

---

## prod 적용 전 필수 확인

```bash
# 플랜 파일로 저장 후 검토
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt
# 삭제 예정 리소스 확인
grep "will be destroyed" tfplan.txt
# 검토한 플랜 그대로 적용
terraform apply tfplan.binary
```

---

## 주요 주의사항

- `*.tfvars` 파일 Git 커밋 금지 (`*.tfvars.example`만 허용)
- 단일 상태 파일로 모든 리소스 관리 금지
- prod `prevent_destroy` 없이 stateful 리소스 정의 금지
- Route53 헬스 체크 CloudWatch 알람은 반드시 `us-east-1`에 생성
- EKS: Karpenter 설치 전 클러스터 먼저 배포 필요

---

## 현재 구현 상태

### 레거시 패턴 (modules/ + envs/)

| 모듈 | modules | envs/dev | envs/prod | Makefile | pre-commit | README |
|------|---------|----------|-----------|----------|------------|--------|
| vpc, ec2, alb, rds, s3, cloudfront | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| waf, iam, kms, secrets-manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eks, ecr, elasticache, dynamodb | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| cloudwatch, bastion, tgw | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| route53, sqs-sns | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| backup, guardduty, codepipeline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Terragrunt 패턴 (dev/ + prod/)

| 구성 요소 | 상태 |
|-----------|------|
| 루트 `terragrunt.hcl` (remote_state + provider 자동 생성) | ✅ |
| `bootstrap/` (S3 + DynamoDB) | ✅ |
| `_envs/` (환경별 변수 참조) | ✅ |
| `dev/`, `prod/` env.hcl | ✅ |
| `dev/*` 전체 모듈 terragrunt.hcl (27개) | ✅ |
| `prod/*` 전체 모듈 terragrunt.hcl (28개) | ✅ |

# CLAUDE.md — Claude Code 작업 가이드

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 규칙 및 컨텍스트 문서입니다.

---

## 저장소 개요

AWS 인프라를 Terraform으로 관리하는 실무 수준의 모듈 모음입니다.
**모든 모듈은 `modules/` + `envs/` 분리 패턴**을 따릅니다.

```
<module>/
├── modules/<module>/    # 재사용 가능한 리소스 정의
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── envs/
│   ├── dev/             # 개발 환경 (비용 최소, force_destroy = true)
│   └── prod/            # 운영 환경 (완전한 보호, 알람 활성화)
├── Makefile
├── .pre-commit-config.yaml
├── terraform.tfvars.example
└── README.md
```

---

## 언어 및 스타일 규칙

- **문서(README, CLAUDE.md)는 반드시 한국어로 작성**
- **코드 주석도 한국어** 사용 — 모듈 상단에 `### === ... ===` 블록, 섹션 구분에 `### --- ... ---` 사용
- README 스타일 기준: `eks/README.md` 참고 (사전 요구사항 → 설정 값 → 배포 순서 → 확인 → 삭제 → 트러블슈팅)

### 코드 주석 패턴

```hcl
### =============================================================================
### modules/example/main.tf
### 리소스 설명
### =============================================================================

### ---------------------------------------------------------------
### 섹션 제목
### 부가 설명
### ---------------------------------------------------------------
resource "aws_example" "this" {
  # ...
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
| 퍼블릭 서브넷 | `10.10.0.x/24` ~ | `10.0.0.x/24` ~ |
| 프라이빗 서브넷 | `10.10.10.x/24` ~ | `10.0.10.x/24` ~ |

---

## 모듈 변수 패턴

모든 모듈은 다음 공통 변수를 반드시 포함합니다.

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

### 공통 태그 패턴 (envs/dev/main.tf)

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "YYYY-MM-DD"
  }
}
```

---

## backend.tf 패턴

모든 env 디렉토리의 `backend.tf`는 다음 형식을 따릅니다.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "{env}/{module}/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "my-company-terraform-locks"
  }
}
```

상태 키 명명 규칙: `{환경}/{모듈}/terraform.tfstate`
예: `prod/vpc/terraform.tfstate`, `dev/eks/terraform.tfstate`

---

## Makefile 표준 타겟

모든 모듈의 Makefile은 동일한 인터페이스를 제공합니다.

```makefile
make init ENV=dev        # terraform init (백엔드 포함)
make plan ENV=dev        # terraform plan
make apply ENV=prod      # terraform apply
make destroy ENV=dev     # terraform destroy
make fmt                 # terraform fmt -recursive
make validate            # terraform validate
make output ENV=dev      # terraform output
```

---

## 새 모듈 추가 시 체크리스트

새 모듈을 추가하거나 기존 모듈을 수정할 때 반드시 확인합니다.

- [ ] `modules/<name>/main.tf` — `### ===` 헤더 주석, 섹션별 `### ---` 구분자
- [ ] `modules/<name>/variables.tf` — `project_name`, `environment`(validation 포함), `common_tags` 필수
- [ ] `modules/<name>/outputs.tf` — 타 모듈에서 참조할 출력값 포함
- [ ] `envs/dev/`, `envs/prod/` — 각각 `main.tf`, `variables.tf`, `terraform.tfvars`, `backend.tf`
- [ ] `terraform.tfvars.example` — 시크릿 제외한 예시 파일
- [ ] `Makefile` — 표준 타겟 포함
- [ ] `.pre-commit-config.yaml` — fmt, validate, tflint 훅
- [ ] `README.md` — 모듈별 README (EKS README 스타일 기준)
- [ ] 루트 `README.md` 모듈 디렉토리 표에 추가

---

## Pre-commit 훅

각 모듈의 `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

설치 및 실행:
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

---

## 주요 주의사항

### 절대 하지 말 것

- `*.tfvars` 파일 Git 커밋 (`.gitignore`로 제외됨 — `*.tfvars.example`만 허용)
- 단일 상태 파일로 모든 리소스 관리 (모듈별·환경별 분리 필수)
- prod 환경 `prevent_destroy` 없이 stateful 리소스(RDS, S3 데이터 버킷 등) 정의

### prod 적용 전 필수 확인

```bash
# 플랜 파일로 저장 후 검토
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt
# 삭제 예정 리소스 확인
grep "will be destroyed" tfplan.txt
# 검토한 플랜 그대로 적용
terraform apply tfplan.binary
```

### Route53 헬스 체크 알람

Route53 헬스 체크 CloudWatch 알람은 **반드시 `us-east-1`** 리전에 생성해야 합니다.
`route53` 모듈은 `aws.us_east_1` provider alias를 사용하므로 env의 `main.tf`에서 해당 provider를 선언해야 합니다.

### EKS 배포 순서

EKS는 Karpenter 설치 전에 클러스터가 먼저 존재해야 합니다.

```bash
terraform apply -target=module.vpc -target=module.eks
terraform apply   # Karpenter 포함 전체 적용
```

---

## 현재 구현 상태

| 모듈 | modules | envs/dev | envs/prod | Makefile | pre-commit | README |
|------|---------|----------|-----------|----------|------------|--------|
| vpc, ec2, alb, rds, s3, cloudfront | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| waf, iam, kms, secrets-manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eks, ecr, elasticache, dynamodb | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| cloudwatch, bastion, tgw | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| route53, sqs-sns | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| backup, guardduty | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| codepipeline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

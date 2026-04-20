# CLAUDE.md — terraform-practice 작업 가이드

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 규칙 및 컨텍스트 문서입니다.

---

## 저장소 개요

AWS 인프라를 Terraform으로 관리하는 실무 수준의 모듈 모음입니다.
**모든 모듈은 `modules/` + `envs/` 분리 패턴**을 따릅니다.

---

## 디렉토리 구조

```
terraform-practice/
├── CLAUDE.md                  # 이 파일 (자동 로드)
├── .claude/
│   ├── settings.json          # 권한 설정 (apply/destroy 차단) + PostToolUse 훅
│   └── commands/              # 커스텀 슬래시 명령어
│       ├── new-doc.md         # /new-doc — 새 모듈 문서 생성
│       ├── new-runbook.md     # /new-runbook — 새 런북 생성
│       ├── review-doc.md      # /review-doc — 코드/문서 검토
│       ├── add-troubleshooting.md  # /add-troubleshooting — 트러블슈팅 추가
│       └── search-kb.md       # /search-kb — 지식베이스 검색
├── agents/                    # 전문 에이전트 정의
│   ├── doc-writer.md          # Terraform 문서 작성 전문가
│   ├── module-reviewer.md     # 모듈 코드 리뷰 전문가
│   ├── security-auditor.md    # 보안 감사 전문가
│   └── cost-optimizer.md      # 비용 최적화 전문가
├── templates/                 # 문서 템플릿
│   ├── service-doc.md         # 모듈 README 템플릿
│   ├── runbook.md             # 운영 런북 템플릿
│   └── incident-report.md     # 장애 보고서 템플릿
├── rules/                     # Claude 작성 규칙
│   ├── doc-writing.md         # 문서 작성 원칙
│   ├── terraform-conventions.md  # Terraform 코드 표준
│   ├── security-checklist.md  # 보안 체크리스트
│   └── monitoring.md          # 모니터링 지침
├── <module>/                  # 각 AWS 서비스 모듈
│   ├── modules/<module>/      # 재사용 가능한 리소스 정의
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── envs/
│   │   ├── dev/               # 개발 환경 (비용 최소, force_destroy=true)
│   │   └── prod/              # 운영 환경 (완전한 보호, 알람 활성화)
│   ├── Makefile
│   ├── .pre-commit-config.yaml
│   └── README.md
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

## Makefile 표준 타겟

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

| 모듈 | modules | envs/dev | envs/prod | Makefile | pre-commit | README |
|------|---------|----------|-----------|----------|------------|--------|
| vpc, ec2, alb, rds, s3, cloudfront | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| waf, iam, kms, secrets-manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| eks, ecr, elasticache, dynamodb | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| cloudwatch, bastion, tgw | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| route53, sqs-sns | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| backup, guardduty, codepipeline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

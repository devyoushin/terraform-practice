# Terraform Ops

Terraform/Terragrunt 실행 자산과 운영 보조 자료를 모아둔 디렉터리입니다. 최상위 `README.md`는 학습 로드맵과 전체 구조를 설명하고, 이 문서는 `ops/` 안에서 무엇을 어디에 두는지 설명합니다.

## 구조 원칙

`ops/`는 세 계층으로 나눕니다.

| 계층 | 경로 | 역할 |
|------|------|------|
| State bootstrap | `bootstrap/` | Terragrunt remote state가 사용할 S3 버킷과 DynamoDB lock 테이블을 최초 1회 생성 |
| Live configuration | `live/<account>/<region>/<env>/` | 실제 plan/apply 진입점. 각 디렉터리의 `terragrunt.hcl`이 모듈 소스를 호출 |
| Module catalog | `modules/` | 재사용 Terraform 모듈, 모듈별 README, standalone Terraform 예제 |

`live/` 하위 경로는 remote state key에 직접 영향을 줍니다. 이미 운영 중인 환경에서는 임의로 옮기지 않습니다.

## 디렉터리 맵

```text
ops/
├── README.md
├── terragrunt.hcl              # 모든 live config가 include하는 루트 설정
├── bootstrap/                  # S3 backend + DynamoDB lock 최초 생성
├── envs/                       # 환경 기준값 참조 문서
│   ├── dev.hcl
│   └── prod.hcl
├── live/                       # 계정/리전/환경별 live configuration
│   ├── nonprod/
│   │   ├── account.hcl
│   │   └── ap-northeast-2/
│   │       ├── region.hcl
│   │       └── dev/
│   │           ├── env.hcl
│   │           └── <service>/terragrunt.hcl
│   └── prod/
│       ├── account.hcl
│       └── ap-northeast-2/
│           ├── region.hcl
│           └── prod/
│               ├── env.hcl
│               └── <service>/terragrunt.hcl
├── modules/                    # 모듈 카탈로그
│   └── <service>/
│       ├── README.md           # 모듈 목적, 입력, 출력, 운영 주의사항
│       ├── modules/<name>/     # 실제 재사용 Terraform module source
│       └── envs/               # standalone Terraform 예제. 권장 실행 경로는 아님
├── scripts/                    # 반복 plan/state 점검 스크립트
└── outputs/                    # plan, graph, 감사 결과 보관 위치
```

## 각 영역의 책임

| 경로 | 넣는 것 | 넣지 않는 것 |
|------|---------|--------------|
| `bootstrap/` | backend를 만들기 위한 순수 Terraform 코드 | 서비스 리소스, 애플리케이션 인프라 |
| `live/<account>/<region>/<env>/` | 환경별 `terragrunt.hcl`, dependency, 입력값 | 재사용 모듈 구현 코드 |
| `modules/<service>/modules/` | 재사용 가능한 Terraform module source | 환경별 값, state backend 설정 |
| `modules/<service>/envs/` | Terraform 단독 실행 예제와 비교 학습용 코드 | 운영 apply 진입점 |
| `envs/` | 환경 기준값 참조 문서 | Terragrunt가 자동으로 읽는 live `env.hcl` 대체 파일 |
| `scripts/` | 반복 가능한 조회, plan, state 점검 스크립트 | 임시 one-off 명령 |
| `outputs/` | 저장할 가치가 있는 plan/graph/점검 결과 | `.tfstate`, secret, credential |

## Terragrunt 호출 흐름

```text
ops/live/nonprod/ap-northeast-2/dev/vpc/terragrunt.hcl
  ├─ include root: ops/terragrunt.hcl
  ├─ read env:    ops/live/nonprod/ap-northeast-2/dev/env.hcl
  └─ source:      ops/modules/vpc/modules/vpc
```

루트 `terragrunt.hcl`은 다음을 공통으로 제공합니다.

- S3 remote state backend
- DynamoDB state lock
- AWS provider와 Terraform required provider 자동 생성
- `project_name`, `aws_region`, `environment`, `common_tags` 공통 입력값

## 새 리소스를 추가하는 기준

1. 기존 모듈에 입력값만 추가하면 되는 경우: `live/nonprod/ap-northeast-2/dev/<service>/terragrunt.hcl`, `live/prod/ap-northeast-2/prod/<service>/terragrunt.hcl`만 수정합니다.
2. 재사용 리소스 구현이 필요한 경우: `modules/<service>/modules/<service>/`에 Terraform 코드를 둡니다.
3. 새 서비스 도메인이 필요한 경우: `modules/<service>/README.md`와 각 live 환경의 `<service>/terragrunt.hcl`을 함께 만듭니다.
4. 운영 적용은 `live/` 하위 환경에서만 수행합니다. `modules/<service>/envs/`는 standalone 예제입니다.

## 기본 실행 흐름

```bash
# 1. 최초 1회 remote state 인프라 생성
cd ops/bootstrap
terraform init
terraform apply

# 2. 단일 모듈 plan
cd ../live/nonprod/ap-northeast-2/dev/vpc
terragrunt init
terragrunt plan

# 3. 환경 전체 plan
cd ../../..
terragrunt run-all plan --terragrunt-working-dir ops/live/nonprod/ap-northeast-2/dev
```

## 운영 기준

- `prod` apply 전에는 `../docs/03-operations/pre-apply-checklist.md`를 먼저 확인합니다.
- 새 모듈이나 큰 변경은 `../docs/03-operations/module-review-checklist.md` 기준으로 리뷰합니다.
- 예상하지 못한 변경이 보이면 `../docs/03-operations/drift-detection-runbook.md` 흐름으로 원인을 분리합니다.
- 기존 리소스를 Terraform 관리 대상으로 편입할 때는 `../docs/03-operations/state-import-runbook.md`를 사용합니다.
- 장기 보관할 plan, dependency graph, 감사 결과는 `outputs/` 아래에 날짜별로 저장합니다.
- 민감정보는 코드, `outputs/`, plan 텍스트에 남기지 않습니다.

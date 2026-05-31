# Terraform Ops

Terraform/Terragrunt 실행 자산과 운영 보조 자료를 모아둔 디렉터리입니다. 최상위 `README.md`는 학습 로드맵과 전체 구조를 설명하고, 이 문서는 실제 실행과 운영 점검 기준을 다룹니다.

## 구성

| 경로 | 내용 |
|------|------|
| `terragrunt.hcl` | 공통 remote state, provider 자동 생성, 환경 공통 설정 |
| `_envs/` | dev/prod 공통 변수 참조 |
| `bootstrap/` | remote state용 S3 버킷과 DynamoDB Lock 테이블 최초 생성 |
| `dev/` | dev 환경 Terragrunt live configuration |
| `prod/` | prod 환경 Terragrunt live configuration |
| `legacy/` | 재사용 Terraform 모듈과 레거시 직접 실행 예제 |
| `scripts/` | 반복 점검용 보조 스크립트 |
| `outputs/` | plan, graph, 점검 결과 산출물 보관 위치 |

## 기본 실행 흐름

```bash
# 1. 최초 1회 remote state 인프라 생성
cd ops/bootstrap
terraform init
terraform apply

# 2. 단일 모듈 plan
cd ../dev/vpc
terragrunt init
terragrunt plan

# 3. 환경 전체 plan
cd ../../..
terragrunt run-all plan --terragrunt-working-dir ops/dev
```

## 운영 기준

- `prod` apply 전에는 `../docs/checklists/pre-apply.md`를 먼저 확인합니다.
- 새 모듈이나 큰 변경은 `../docs/checklists/module-review.md` 기준으로 리뷰합니다.
- 예상하지 못한 변경이 보이면 `../docs/runbooks/drift-detection.md` 흐름으로 원인을 분리합니다.
- 기존 리소스를 Terraform 관리 대상으로 편입할 때는 `../docs/runbooks/state-import.md`를 사용합니다.
- 장기 보관할 plan, dependency graph, 감사 결과는 `outputs/` 아래에 날짜별로 저장합니다.

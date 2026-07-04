# Terraform Docs

이 디렉터리는 Terraform/Terragrunt 저장소를 읽고 운영할 때 필요한 문서를 목적별로 모은다.

문서는 숫자 접두어로 우선순위를 드러낸다. `01-guide`는 처음 읽는 문서이고, `99-agents`는 AI 작업 보조 지침이라 일반 독자는 가장 나중에 보면 된다.

## 어디서 시작할까

| 상황 | 먼저 볼 문서 |
|------|--------------|
| 저장소를 처음 본다 | [시작 가이드](01-guide/getting-started.md) |
| 새 모듈을 만들거나 기존 모듈을 수정한다 | [모듈 구축 가이드](01-guide/module-build-guide.md) |
| Terraform 코드 기준을 확인한다 | [Terraform 코드 표준](02-standards/terraform-conventions.md) |
| apply 전 위험을 점검한다 | [Apply 전 체크리스트](03-operations/pre-apply-checklist.md) |
| drift 또는 import를 처리한다 | [운영 절차](03-operations/drift-detection-runbook.md), [State Import 런북](03-operations/state-import-runbook.md) |
| 실제 명령 실행 방법을 본다 | [ops 실행 가이드](../ops/README.md) |

## 문서 구조

| 위치 | 목적 | 문서 |
|------|------|------|
| `01-guide/` | 처음 읽는 안내서 | `getting-started.md`, `module-build-guide.md` |
| `02-standards/` | 코드/문서 작성 기준 | `terraform-conventions.md`, `security.md`, `monitoring.md`, `doc-writing.md` |
| `03-operations/` | 적용 전 점검과 운영 절차 | `pre-apply-checklist.md`, `module-review-checklist.md`, `drift-detection-runbook.md`, `state-import-runbook.md`, `outputs.md` |
| `04-templates/` | 복사해서 쓰는 문서 골격 | `service-doc.md`, `runbook.md`, `incident-report.md` |
| `99-agents/` | AI 작업 보조 지침 | `doc-writer.md`, `module-reviewer.md`, `security-auditor.md`, `cost-optimizer.md` |

## 코드 위치

| 경로 | 내용 |
|------|------|
| `../ops/bootstrap/` | Remote State용 S3/DynamoDB 최초 생성 코드 |
| `../ops/live/nonprod/ap-northeast-2/dev/` | dev 환경 Terragrunt 호출부 |
| `../ops/live/prod/ap-northeast-2/prod/` | prod 환경 Terragrunt 호출부 |
| `../ops/modules/` | 재사용 Terraform 모듈과 standalone 직접 실행 구조 |
| `../ops/envs/` | 환경별 공통 변수 참조 파일 |
| `../ops/scripts/` | 반복 점검용 보조 스크립트 |
| `../ops/outputs/` | plan, graph, 점검 결과 산출물 보관 위치 |
| `../ops/README.md` | 실제 Terraform/Terragrunt 실행 가이드 |

## 문서 읽는 순서

1. [시작 가이드](01-guide/getting-started.md)
2. [모듈 구축 가이드](01-guide/module-build-guide.md)
3. [Terraform 코드 표준](02-standards/terraform-conventions.md)
4. [Apply 전 체크리스트](03-operations/pre-apply-checklist.md)
5. [Drift Detection 런북](03-operations/drift-detection-runbook.md)
6. [State Import 런북](03-operations/state-import-runbook.md)
7. [운영 실행 가이드](../ops/README.md)

## 작업 기준

- 문서, 규칙, 체크리스트, 런북, 템플릿은 `docs/` 아래의 목적별 폴더에 둔다.
- 실행 코드는 `ops/` 아래의 기존 환경/모듈 경계 안에서 수정한다.
- 모듈 바로 옆의 `ops/modules/*/README.md`는 해당 모듈의 로컬 설명서로 유지한다.
- `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크다. AI 작업 지침은 `CLAUDE.md`를 원본으로 관리한다.

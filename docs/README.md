# Terraform Docs

이 디렉터리는 Terraform/Terragrunt를 처음 읽는 사람을 위한 안내서, 규칙, 체크리스트, 런북을 모은다.

## 어디서 시작할까

| 순서 | 문서 | 용도 |
|------|------|------|
| 1 | `getting-started.md` | 무엇부터 읽고 어디로 가야 하는지 |
| 2 | `module-build-guide.md` | 새 모듈과 Terragrunt 구조를 이해할 때 |
| 3 | `rules/README.md` | Terraform 작성 규칙을 볼 때 |
| 4 | `checklists/README.md` | 적용 전에 점검할 때 |
| 5 | `runbooks/README.md` | drift, import, 상태 문제를 다룰 때 |
| 6 | `agents/README.md` | AI 작업 지침이 필요할 때 |
| 7 | `templates/README.md` | 문서 골격이 필요할 때 |
| 8 | `../ops/README.md` | 실제 실행 경로를 볼 때 |

## 문서 구조

| 구분 | 위치 | 의미 |
|------|------|------|
| 시작 문서 | `getting-started.md`, `module-build-guide.md` | 저장소 읽는 순서와 구조 이해 |
| 규칙 문서 | `rules/` | Terraform 코드/문서 작성 기준 |
| 체크리스트 | `checklists/` | apply 전 확인 기준 |
| 런북 | `runbooks/` | drift, import, 상태 이슈 대응 |
| 템플릿 | `templates/` | README, 런북, 장애 보고서 골격 |
| AI 지침 | `agents/` | 문서/모듈 리뷰용 작업 지침 |
| 산출물 기준 | `outputs.md` | plan, graph, 점검 결과 보관 방식 |

## 코드 위치

| 경로 | 내용 |
|------|------|
| `../ops/bootstrap/` | Remote State용 S3/DynamoDB 최초 생성 코드 |
| `../ops/dev/` | dev 환경 Terragrunt 호출부 |
| `../ops/prod/` | prod 환경 Terragrunt 호출부 |
| `../ops/legacy/` | 재사용 Terraform 모듈과 레거시 직접 실행 구조 |
| `../ops/_envs/` | 환경별 공통 변수 참조 파일 |
| `../ops/scripts/` | 반복 점검용 보조 스크립트 |
| `../ops/outputs/` | plan, graph, 점검 결과 산출물 보관 위치 |
| `../ops/README.md` | 실제 Terraform/Terragrunt 실행 가이드 |

## 문서 읽는 순서

1. `getting-started.md`
2. `module-build-guide.md`
3. `rules/README.md`
4. `checklists/README.md`
5. `runbooks/README.md`
6. `agents/README.md`
7. `templates/README.md`
8. `../ops/README.md`

## 작업 기준

- 문서, 규칙, 템플릿은 `docs/` 아래에 둔다.
- 실행 코드는 `ops/` 아래의 기존 환경/모듈 경계 안에서 수정한다.
- 모듈 바로 옆의 `ops/legacy/*/README.md`는 해당 모듈의 로컬 설명서로 유지한다.
- `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크다. AI 작업 지침은 `CLAUDE.md`를 원본으로 관리한다.

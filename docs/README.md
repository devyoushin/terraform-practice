# Terraform Practice Docs

Terraform/Terragrunt 학습과 운영 보조 문서는 이 디렉터리에서 관리합니다.

| 폴더 | 내용 |
|------|------|
| `agents/` | Terraform 문서 작성, 모듈 리뷰, 보안 감사, 비용 최적화용 AI 작업 지침 |
| `rules/` | 문서 작성 규칙, Terraform 컨벤션, 보안/모니터링 체크리스트 |
| `templates/` | 서비스 문서, 런북, 장애 보고서 템플릿 |

실제 인프라 코드는 `ops/` 아래의 `dev/`, `prod/`, `legacy/`, `bootstrap/`에 둡니다.

## 코드 위치

| 경로 | 내용 |
|------|------|
| `../ops/bootstrap/` | Remote State용 S3/DynamoDB 최초 생성 코드 |
| `../ops/dev/` | dev 환경 Terragrunt 호출부 |
| `../ops/prod/` | prod 환경 Terragrunt 호출부 |
| `../ops/legacy/` | 재사용 Terraform 모듈과 레거시 직접 실행 구조 |
| `../ops/_envs/` | 환경별 공통 변수 참조 파일 |

## 작업 기준

- 설명 문서, 규칙, 템플릿은 `docs/` 아래에 둡니다.
- Terraform/Terragrunt 실행 코드는 `ops/` 아래의 기존 환경/모듈 경계 안에서 수정합니다.
- `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크입니다. AI 작업 지침은 `CLAUDE.md`를 원본으로 관리합니다.

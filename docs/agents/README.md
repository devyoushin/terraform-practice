# AI 작업 지침

이 디렉터리는 Terraform 저장소를 다룰 때 사용하는 AI 작업 지침을 모은다.

## 문서 목록

| 문서 | 용도 |
|------|------|
| `doc-writer.md` | 모듈 README와 설명 문서 작성 |
| `module-reviewer.md` | 모듈 구조와 변경 안전성 검토 |
| `security-auditor.md` | 보안/권한/노출 범위 점검 |
| `cost-optimizer.md` | 비용 관점의 설계 검토 |

## 언제 보나

- README를 새로 쓰거나 정리할 때는 `doc-writer.md`
- 모듈 변경을 리뷰할 때는 `module-reviewer.md`
- IAM, KMS, 보안 그룹, 시크릿이 걸릴 때는 `security-auditor.md`
- 비용이 민감한 리소스를 다룰 때는 `cost-optimizer.md`

## 관련 문서

- `../../CLAUDE.md`
- `../rules/README.md`
- `../templates/README.md`


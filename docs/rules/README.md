# 규칙 문서

이 디렉터리는 Terraform 저장소에서 지켜야 할 작성 기준과 컨벤션을 모은다.

## 문서 목록

| 문서 | 용도 |
|------|------|
| `doc-writing.md` | README, 설명 문서, 표준 문서 구조 |
| `terraform-conventions.md` | 모듈 구조, 변수 패턴, backend, Makefile 기준 |
| `security-checklist.md` | 보안 점검 기준 |
| `monitoring.md` | 모니터링/알람 관련 문서 기준 |

## 어떻게 쓰나

1. 새 모듈이나 문서를 쓸 때는 `doc-writing.md`를 본다.
2. 코드 구조와 변수 패턴은 `terraform-conventions.md`를 따른다.
3. 권한, 암호화, 파괴 방지 설정은 `security-checklist.md`를 확인한다.
4. 모니터링 관련 변경은 `monitoring.md`를 확인한다.

## 관련 문서

- `../agents/README.md`
- `../templates/README.md`
- `../module-build-guide.md`


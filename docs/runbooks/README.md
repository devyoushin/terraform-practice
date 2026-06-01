# 런북

이 디렉터리는 상태 관리와 예상치 못한 변경을 다루는 운영 절차를 모은다.

## 문서 목록

| 문서 | 용도 |
|------|------|
| `drift-detection.md` | state와 실제 리소스의 차이 확인 |
| `state-import.md` | 기존 리소스를 Terraform 관리 대상으로 편입 |

## 어떻게 쓰나

1. drift가 의심되면 `drift-detection.md`를 본다.
2. 콘솔에서 만든 리소스를 관리 대상으로 넣어야 하면 `state-import.md`를 본다.
3. 작업 후에는 `plan`을 다시 만들어 차이를 확인한다.

## 관련 문서

- `../checklists/README.md`
- `../module-build-guide.md`


# Terraform Outputs

이 디렉터리는 실행 산출물을 임시 또는 날짜별로 보관하는 위치입니다.

보관 예시:

- `YYYYMMDD/dev-plan.txt`
- `YYYYMMDD/prod-plan.txt`
- `YYYYMMDD/dependency-graph.svg`
- `YYYYMMDD/drift-check.md`

민감 정보가 포함된 plan, state, provider debug log는 커밋하지 않습니다.

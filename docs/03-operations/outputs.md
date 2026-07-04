# Terraform 실행 산출물 보관 기준

실행 산출물은 `ops/outputs/` 아래에 임시 또는 날짜별로 보관합니다. 이 문서는 어떤 파일을 남기고 어떤 파일을 커밋하지 않을지 정하는 기준입니다.

보관 예시:

- `YYYYMMDD/dev-plan.txt`
- `YYYYMMDD/prod-plan.txt`
- `YYYYMMDD/dependency-graph.svg`
- `YYYYMMDD/drift-check.md`

민감 정보가 포함된 plan, state, provider debug log는 커밋하지 않습니다.

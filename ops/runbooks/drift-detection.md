# Drift Detection 런북

## 목적

Terraform state와 실제 클라우드 리소스 사이의 차이를 주기적으로 확인합니다.

## 절차

1. 대상 환경을 확인합니다.

```bash
terragrunt run-all plan --terragrunt-working-dir ops/dev
terragrunt run-all plan --terragrunt-working-dir ops/prod
```

2. plan 결과를 분류합니다.

| 유형 | 대응 |
|------|------|
| 의도한 코드 변경 | 리뷰 후 apply |
| 콘솔 수동 변경 | 코드 반영 또는 수동 변경 원복 |
| provider computed value 변경 | provider 버전과 ignore_changes 필요 여부 확인 |
| 삭제된 리소스 | 복구 또는 state 정리 여부 결정 |

3. 결과를 보관합니다.

```bash
mkdir -p ops/outputs/$(date +%Y%m%d)
terragrunt run-all plan --terragrunt-working-dir ops/prod \
  > ops/outputs/$(date +%Y%m%d)/prod-drift-plan.txt
```

## 주의사항

- drift 확인 목적의 plan은 기본적으로 apply하지 않습니다.
- prod에서 `destroy`가 보이면 변경 주체와 영향 범위를 먼저 확인합니다.

# Terraform Apply 전 체크리스트

## 공통

- `terraform fmt` 또는 `terragrunt hclfmt`가 완료되었는가?
- `terraform validate` 또는 `terragrunt validate`가 통과했는가?
- plan 결과에 의도하지 않은 `destroy` 또는 `replace`가 없는가?
- 변경 대상 리소스의 태그, 네이밍, 환경 값이 맞는가?
- backend, provider, region, account가 대상 환경과 일치하는가?

## prod 추가 확인

- `prevent_destroy`, deletion protection, backup retention이 필요한 리소스에 적용되었는가?
- RDS, ElastiCache, EKS, ALB 등 장애 영향이 큰 리소스 변경은 점검 창이 확보되었는가?
- KMS 키, IAM policy, security group 변경은 최소 권한 원칙을 만족하는가?
- rollback 방법이 문서화되어 있고 담당자가 확인했는가?
- plan 파일 또는 실행 로그를 `ops/outputs/` 아래에 보관했는가?

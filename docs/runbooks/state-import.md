# Terraform State Import 런북

## 목적

이미 존재하는 AWS 리소스를 Terraform 관리 대상으로 편입합니다.

## 절차

1. 리소스를 표현할 Terraform 코드 또는 모듈 호출부를 먼저 작성합니다.
2. import 주소와 실제 리소스 ID를 확인합니다.

```bash
terraform state list
terraform import 'module.example.aws_resource.this' resource-id
```

Terragrunt 환경에서는 대상 모듈 디렉터리에서 실행합니다.

```bash
cd ops/live/prod/ap-northeast-2/prod/vpc
terragrunt import 'module.vpc.aws_vpc.this' vpc-xxxxxxxx
```

3. import 후 plan을 확인합니다.

```bash
terragrunt plan
```

4. plan에서 불필요한 변경이 나오면 코드 값을 실제 리소스와 맞춥니다.

## 검토 기준

- import 전후 state 백업을 남겼는가?
- 리소스 태그와 lifecycle 설정이 실제 운영 기준과 맞는가?
- `force_destroy`, `deletion_protection`, `prevent_destroy` 같은 보호 옵션을 확인했는가?

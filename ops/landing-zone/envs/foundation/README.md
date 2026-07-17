# Landing Zone Foundation

AWS Organizations OU, 공통 계정, 서비스별 `dev/stg/prd` 계정, 서비스별 CIDR 계획을 생성하거나 검증하는 실행 경로다.

## 생성 대상

| 구분 | 수량 | 설명 |
|------|------|------|
| Root OU | 6개 | Security, Infrastructure, SharedServices, Workloads, Sandbox, Suspended |
| Workload 하위 OU | 3개 | Dev, Stg, Prd |
| Foundation 계정 | 4개 | Audit, LogArchive, Network, SharedServices |
| 서비스 계정 | 150개 | 50개 서비스 x dev/stg/prd |
| 서비스 CIDR | 50개 | `10.100.0.0/16`에서 서비스별 `/24` |

## 실행 전 수정

1. `../../catalog/organization.json`의 `email_domain`을 실제 회사 도메인으로 바꾼다.
2. Foundation 계정 이메일이 실제로 수신 가능한 별칭인지 확인한다.
3. 이미 존재하는 계정은 Terraform import 전략을 먼저 정한다.
4. Control Tower에서 등록된 OU와 신규 OU 생성 정책을 확인한다.

## 실행

```bash
cd ops/landing-zone/envs/foundation
terraform init
terraform plan
```

`create_organization = false`가 기본값이다. 이미 Organizations가 있는 관리 계정에서 OU와 계정만 관리하는 흐름을 전제로 한다.

## 주의사항

- `aws_organizations_account`는 계정 생성 후 이메일, 이름, 역할 변경에 제한이 있다.
- 이 모듈은 계정 삭제를 막기 위해 `prevent_destroy = true`를 사용한다.
- Control Tower Account Factory로 이미 생성한 계정은 import 후 관리해야 한다.
- 150개 계정을 한 번에 생성하면 AWS Organizations 계정 생성 제한에 걸릴 수 있으므로 실제 운영에서는 wave 단위로 나눈다.

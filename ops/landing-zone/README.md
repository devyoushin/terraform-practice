# 엔터프라이즈 Landing Zone 설계

이 디렉터리는 AWS Organizations, Control Tower 운영 경계, 계정 분리, 서비스별 IP 대역을 한곳에서 관리하기 위한 초안이다.

## 설계 원칙

| 항목 | 기준 |
|------|------|
| 조직 기준 | AWS Organizations를 단일 관리 계정에서 운영 |
| Control Tower | 랜딩존 활성화와 Account Factory 운영은 관리 계정에서 별도 승인 후 진행 |
| 환경 구분 | `dev`, `stg`, `prd`를 계정 단위로 분리 |
| 서비스 구분 | 50개 서비스마다 환경별 계정과 CIDR 블록을 별도 할당 |
| Public cloud 대역 | `10.100.0.0/16` |
| 서비스 단위 VPC | 서비스별 `/24`, 환경별 `/26` |
| Terraform 상태 | foundation 단계는 서비스 인프라 state와 분리 |

## 디렉터리 구조

```text
ops/landing-zone/
├── README.md
├── catalog/
│   ├── accounts.auto.tfvars.json   # OU, 공통 계정, 50개 서비스 계정 정의
│   └── services.yaml               # 사람이 읽는 서비스/IP 할당표
├── envs/foundation/                # Organizations 계정/OU와 CIDR 계획 검증 진입점
└── modules/
    ├── organization/               # AWS Organizations OU/account 모듈
    └── network-cidr-plan/          # 서비스별 CIDR 계획 검증/출력 모듈
```

## 적용 순서

1. 관리 계정에서 Control Tower 랜딩존을 활성화한다.
2. `catalog/accounts.auto.tfvars.json`의 이메일 도메인과 계정명을 실제 조직 기준으로 수정한다.
3. `ops/landing-zone/envs/foundation`에서 `terraform init`, `terraform plan`을 실행한다.
4. 계정 생성 후 발급된 account ID를 `ops/live/<account>/account.hcl` 또는 신규 live 계층에 반영한다.
5. 서비스별 VPC 모듈은 `network_plan` 출력의 `dev_cidr`, `stg_cidr`, `prd_cidr`를 사용한다.

## Control Tower 경계

Control Tower는 랜딩존 버전, 등록 OU, Account Factory, guardrail 상태가 계정의 기존 상태와 강하게 결합된다. 따라서 이 저장소에서는 다음처럼 역할을 나눈다.

| 영역 | Terraform 관리 | 비고 |
|------|----------------|------|
| AWS Organizations OU | 가능 | `modules/organization` |
| 신규 AWS Account | 가능 | `aws_organizations_account` |
| SCP 연결 | 확장 예정 | 조직 정책 승인 후 추가 |
| Control Tower 랜딩존 활성화 | 별도 승인 필요 | 기존 조직 상태 확인 후 실행 |
| Account Factory 등록 | 별도 승인 필요 | Control Tower UI 또는 전용 파이프라인 권장 |

## OU 구조

```text
Root
├── Security
├── Infrastructure
├── SharedServices
├── Workloads
│   ├── Dev
│   ├── Stg
│   └── Prd
├── Sandbox
└── Suspended
```

## 계정 분리 기준

| 계정군 | 목적 |
|--------|------|
| Audit | 보안 감사 로그와 Security Hub delegated admin |
| LogArchive | CloudTrail, Config, VPC Flow Logs 중앙 보관 |
| Network | TGW, 중앙 DNS, egress, inspection VPC |
| SharedServices | CI/CD, artifact, 공통 운영 도구 |
| 서비스 dev/stg/prd | 서비스별 워크로드 실행 계정 |

## IP 할당 기준

`10.100.0.0/16`을 서비스별 `/24`로 나누고, 각 서비스 안에서 환경별 `/26`을 할당한다.

| 환경 | 서비스 내부 대역 |
|------|----------------|
| dev | `10.100.N.0/26` |
| stg | `10.100.N.64/26` |
| prd | `10.100.N.128/26` |
| reserved | `10.100.N.192/26` |

50개 서비스는 `10.100.0.0/24`부터 `10.100.49.0/24`까지 사용한다. `10.100.50.0/24` 이후는 shared, inspection, future 확장용으로 남긴다.

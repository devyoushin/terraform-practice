# Terraform AWS GuardDuty 모듈

재사용 가능한 AWS GuardDuty 위협 탐지 Terraform 모듈입니다. 환경별(dev/staging/prod) 분리 구성을 통해 보안 위협을 자동으로 탐지하고 알림을 발송합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| GuardDuty 탐지기 | CloudTrail, VPC Flow Logs, DNS 쿼리 로그 기반 위협 탐지 |
| S3 위협 탐지 | S3 데이터 이벤트 기반 이상 접근 탐지 |
| Kubernetes 감사 로그 | EKS 환경에서 컨테이너 위협 탐지 (선택적) |
| 악성코드 탐지 | EC2 EBS 볼륨 악성코드 스캔 (추가 비용, 선택적) |
| SNS 알림 | 위협 탐지 즉시 이메일/슬랙/PagerDuty 알림 |
| CloudWatch Events | 심각도 기반 필터링 (1-3: Low, 4-6: Medium, 7-8: High, 9-10: Critical) |
| 신뢰 IP 필터 | 내부 보안 스캐너, 감사 도구 등 알려진 IP 결과 자동 보관 |

---

## GuardDuty 위협 탐지 범주

GuardDuty는 다음 범주의 위협을 자동으로 탐지합니다.

| 범주 | 예시 위협 |
|---|---|
| 자격 증명 도용 | 비정상적인 API 호출, 루트 계정 사용, IAM 정책 변경 |
| 악성코드 | EC2 인스턴스의 C&C 서버 통신, 크립토마이닝 |
| 네트워크 침입 | 비정상적인 포트 스캔, TOR 네트워크 통신 |
| 데이터 유출 | S3 버킷 공개 설정 변경, 대량 데이터 다운로드 |
| 권한 상승 | 비정상적인 IAM 역할 가정, 권한 정책 변경 |
| 컨테이너 공격 | EKS 컨테이너 탈출, 비정상적인 Pod 생성 |

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| 발행 주기 | SIX_HOURS (비용 최소) | ONE_HOUR | FIFTEEN_MINUTES |
| S3 위협 탐지 | 활성화 | 활성화 | 활성화 |
| Kubernetes 감사 | 비활성화 | 선택적 | EKS 사용 시 필수 |
| 악성코드 탐지 | 비활성화 | 선택적 | 활성화 권장 |
| 알림 최소 심각도 | Medium (4) | Medium (4) | Low (1) 권장 |
| 신뢰 IP 필터 | 비활성화 | 선택적 | 활성화 권장 |

---

## 심각도 레벨

| 심각도 | 범위 | 설명 | 권장 대응 |
|---|---|---|---|
| Critical | 9.0 - 10.0 | 즉각적인 침해 위협 | 즉시 대응 (15분 이내) |
| High | 7.0 - 8.9 | 높은 위험도 위협 | 당일 대응 |
| Medium | 4.0 - 6.9 | 중간 위험도 위협 | 48시간 이내 대응 |
| Low | 1.0 - 3.9 | 낮은 위험도 위협 | 검토 후 판단 |

---

## 디렉토리 구조

```
guardduty/
├── modules/guardduty/   # 재사용 가능한 GuardDuty 모듈
│   ├── main.tf          # 탐지기, SNS, CloudWatch Events, 필터 정의
│   ├── variables.tf     # 모듈 입력 변수
│   └── outputs.tf       # 모듈 출력값
├── envs/
│   ├── dev/             # 개발 환경 (SIX_HOURS, 비용 최소화)
│   │   └── main.tf
│   ├── staging/         # 스테이징 환경 (ONE_HOUR)
│   └── prod/            # 운영 환경 (FIFTEEN_MINUTES, 전체 보호)
├── Makefile             # 환경별 작업 자동화
├── .pre-commit-config.yaml
└── README.md
```

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `enable_guardduty` | `bool` | `true` | GuardDuty 탐지기 활성화 여부 |
| `finding_publishing_frequency` | `string` | `"SIX_HOURS"` | 결과 발행 주기 |
| `enable_s3_logs` | `bool` | `true` | S3 로그 기반 위협 탐지 |
| `enable_kubernetes_audit_logs` | `bool` | `false` | Kubernetes 감사 로그 탐지 (EKS용) |
| `enable_malware_protection` | `bool` | `false` | EC2 악성코드 탐지 (추가 비용) |
| `alert_email` | `string` | `""` | 알림 수신 이메일 (빈 값이면 생략) |
| `min_severity` | `number` | `4` | 알림 최소 심각도 (1-10) |
| `enable_filter` | `bool` | `false` | 신뢰 IP 필터 활성화 |
| `filter_trusted_ips` | `list(string)` | `[]` | 필터링할 신뢰 IP 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

---

## 모듈 출력값

| 출력값 | 설명 |
|---|---|
| `guardduty_detector_id` | GuardDuty 탐지기 ID |
| `guardduty_detector_arn` | GuardDuty 탐지기 ARN |
| `sns_topic_arn` | 위협 알림용 SNS 토픽 ARN |
| `sns_topic_name` | 위협 알림용 SNS 토픽 이름 |
| `cloudwatch_event_rule_arn` | CloudWatch Event Rule ARN |
| `cloudwatch_event_rule_name` | CloudWatch Event Rule 이름 |

---

## 사전 준비

### 1. 사전 요구사항 확인

```bash
# Terraform 버전 확인 (1.5.0 이상 필요)
terraform version

# AWS 자격증명 설정
aws configure

# GuardDuty가 이미 활성화되어 있는지 확인
aws guardduty list-detectors --region ap-northeast-2
```

> **주의**: AWS 계정당 리전별로 GuardDuty 탐지기는 하나만 존재할 수 있습니다.
> 이미 활성화된 탐지기가 있다면 `enable_guardduty = false` 후 `import`로 가져오거나,
> 기존 탐지기를 먼저 삭제 후 배포하세요.

### 2. IAM 권한 확인

| 서비스 | 필요 권한 |
|---|---|
| GuardDuty | `guardduty:*` |
| SNS | `sns:CreateTopic`, `sns:Subscribe`, `sns:SetTopicAttributes` |
| CloudWatch Events | `events:PutRule`, `events:PutTargets` |
| IAM (data) | `iam:GetPolicy` (계정 정보 조회용) |

---

## 배포 방법

### Makefile 이용 (권장)

```bash
# 개발 환경 배포
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# 운영 환경 배포
make init ENV=prod
make plan ENV=prod
make apply ENV=prod

# 출력값 확인 (SNS 토픽 ARN 등)
make output ENV=prod
```

### 직접 Terraform 명령

```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

---

## 배포 확인

### GuardDuty 탐지기 상태 확인

```bash
# 탐지기 목록 및 상태
aws guardduty list-detectors --region ap-northeast-2

# 탐지기 상세 정보
aws guardduty get-detector \
  --detector-id <DETECTOR_ID> \
  --region ap-northeast-2
```

### 샘플 위협 이벤트 생성 (테스트용)

```bash
# GuardDuty 샘플 findings 생성 — 실제 위협이 아닌 테스트용
aws guardduty create-sample-findings \
  --detector-id <DETECTOR_ID> \
  --finding-types "UnauthorizedAccess:EC2/SSHBruteForce" \
  --region ap-northeast-2
```

> 샘플 이벤트가 생성되면 SNS → 이메일 알림이 정상 동작하는지 확인할 수 있습니다.

### 현재 위협 결과 확인

```bash
# 현재 활성 findings 목록
aws guardduty list-findings \
  --detector-id <DETECTOR_ID> \
  --finding-criteria '{"Criterion":{"service.archived":{"Eq":["false"]}}}' \
  --region ap-northeast-2

# 특정 finding 상세 정보
aws guardduty get-findings \
  --detector-id <DETECTOR_ID> \
  --finding-ids <FINDING_ID> \
  --region ap-northeast-2
```

---

## 사용 예시

### dev 환경: 기본 위협 탐지

```hcl
module "guardduty" {
  source = "../../modules/guardduty"

  project_name = "my-project"
  environment  = "dev"

  enable_guardduty             = true
  finding_publishing_frequency = "SIX_HOURS"  # 비용 최소화

  enable_s3_logs               = true
  enable_kubernetes_audit_logs = false
  enable_malware_protection    = false

  alert_email  = "dev-team@company.com"
  min_severity = 4  # Medium 이상만 알림
}
```

### prod 환경: 전체 보호 활성화

```hcl
module "guardduty" {
  source = "../../modules/guardduty"

  project_name = "my-project"
  environment  = "prod"

  enable_guardduty             = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"  # 실시간에 가까운 탐지

  enable_s3_logs               = true
  enable_kubernetes_audit_logs = true   # EKS 사용 시
  enable_malware_protection    = true   # EC2 악성코드 탐지

  alert_email  = "security-team@company.com"
  min_severity = 1  # 모든 심각도 알림 (Low 포함)

  # 내부 보안 스캐너 IP 제외
  enable_filter      = true
  filter_trusted_ips = ["10.0.1.100", "10.0.2.100"]
}
```

---

## SNS 알림 슬랙 연동 (선택)

GuardDuty 알림을 슬랙으로 받으려면 SNS → Lambda → 슬랙 패턴을 사용합니다.

```bash
# SNS 토픽 ARN 확인
terraform output sns_topic_arn

# SNS 토픽에 슬랙 Lambda 구독 추가
aws sns subscribe \
  --topic-arn <SNS_TOPIC_ARN> \
  --protocol lambda \
  --notification-endpoint <SLACK_LAMBDA_ARN>
```

---

## 리소스 삭제

> GuardDuty를 삭제하면 모든 탐지 이력이 사라집니다. prod 환경에서 신중히 진행하세요.

```bash
make destroy ENV=dev
```

GuardDuty 탐지기 삭제 후에는 재활성화 시 이전 findings이 복원되지 않습니다.

---

## 트러블슈팅

### GuardDuty 탐지기가 이미 존재하는 경우

```bash
# 기존 탐지기 ID 조회
aws guardduty list-detectors --region ap-northeast-2

# Terraform import로 기존 탐지기 관리
terraform import module.guardduty.aws_guardduty_detector.this[0] <DETECTOR_ID>
```

### 이메일 알림이 오지 않는 경우

SNS 이메일 구독은 반드시 **구독 확인 이메일** 수신 후 승인해야 합니다.

```bash
# 구독 상태 확인 (PendingConfirmation이면 이메일 승인 필요)
aws sns list-subscriptions-by-topic \
  --topic-arn <SNS_TOPIC_ARN>
```

### 샘플 Findings가 알림으로 오지 않는 경우

CloudWatch Event Rule의 최소 심각도 필터를 확인하세요.
샘플 Findings는 심각도가 낮을 수 있어 `min_severity` 임계값에 걸릴 수 있습니다.

---

## 비용 참고

| 서비스 | 과금 기준 |
|---|---|
| GuardDuty 기본 | CloudTrail 이벤트 + VPC Flow Logs + DNS 로그 분석량 |
| S3 위협 탐지 | S3 데이터 이벤트 분석량 (별도 과금) |
| Kubernetes 감사 | EKS 감사 로그 분석량 (별도 과금) |
| 악성코드 탐지 | EC2 EBS 볼륨 스캔량 (별도 과금) |

> dev/staging 환경에서는 불필요한 데이터 소스 보호를 비활성화하여 비용을 절약하세요.
> `finding_publishing_frequency = "SIX_HOURS"`로 설정하면 분석 주기를 최소화하여 비용을 절감할 수 있습니다.

---

## 요구사항

| 항목 | 버전 |
|---|---|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 |

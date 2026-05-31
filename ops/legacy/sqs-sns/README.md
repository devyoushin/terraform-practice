# Terraform SQS-SNS 모듈

재사용 가능한 AWS SQS 큐 및 SNS 토픽 관리 Terraform 모듈입니다. 환경별(dev/staging/prod) 분리 구성을 통해 안전하고 일관된 메시지 큐 인프라를 제공합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| SQS 표준 큐 | 메인 큐 + DLQ 자동 생성, redrive policy 설정 |
| SQS FIFO 큐 | 순서 보장 및 중복 제거 지원, 별도 DLQ 포함 |
| SNS 토픽 | 표준/FIFO 토픽 생성, 멀티 구독(이메일/SQS/Lambda/HTTPS) 지원 |
| SNS-SQS 연동 | SQS 큐 정책 자동 생성으로 SNS → SQS 메시지 전달 허용 |
| KMS 암호화 | 선택적 고객 관리형 KMS 키 적용 (prod 권장) |
| CloudWatch 알람 | 큐 깊이 및 DLQ 깊이 실시간 모니터링 |
| SNS 필터 정책 | MessageAttributes 또는 MessageBody 기반 선택적 메시지 전달 |

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| KMS 암호화 | SSE-SQS (기본) | 선택적 KMS | KMS 필수 |
| 메시지 보존 기간 | 4일 | 7일 | 14일 |
| 가시성 타임아웃 | 30초 | 120초 | 300초 |
| DLQ maxReceiveCount | 3 | 5 | 5 |
| CloudWatch 알람 | 비활성화 | 활성화 | 활성화 |
| FIFO 큐 | 비활성화 | 선택적 | 선택적 |
| 큐 깊이 알람 임계값 | - | 100 | 1000 |

---

## 디렉토리 구조

```
sqs-sns/
├── modules/sqs-sns/      # 재사용 가능한 SQS-SNS 모듈
│   ├── main.tf           # SQS 큐, SNS 토픽, 구독, 정책, CloudWatch 알람 정의
│   ├── variables.tf      # 모듈 입력 변수
│   └── outputs.tf        # 모듈 출력값
├── envs/
│   ├── dev/              # 개발 환경
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/          # 스테이징 환경
│   └── prod/             # 운영 환경
├── Makefile              # 환경별 작업 자동화
├── .pre-commit-config.yaml
└── README.md
```

---

## 리소스 명명 규칙

리소스 이름은 아래 패턴으로 자동 생성됩니다.

```
{project_name}-{environment}-{queue_name}         # 메인 큐
{project_name}-{environment}-{queue_name}-dlq     # DLQ
{project_name}-{environment}-{queue_name}-fifo.fifo     # FIFO 큐 (선택)
{project_name}-{environment}-{queue_name}-fifo-dlq.fifo # FIFO DLQ (선택)
{project_name}-{environment}-{topic_name}         # SNS 토픽
```

예시:

| project_name | environment | queue_name | 생성되는 리소스 |
|---|---|---|---|
| `my-project` | `dev` | `events` | `my-project-dev-events` 큐 |
| `my-project` | `prod` | `orders` | `my-project-prod-orders` 큐 + DLQ |

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `queue_name` | `string` | 필수 | SQS 큐 이름 식별자 |
| `topic_name` | `string` | 필수 | SNS 토픽 이름 식별자 |
| `visibility_timeout_seconds` | `number` | `30` | 메시지 가시성 타임아웃 (초) |
| `message_retention_seconds` | `number` | `345600` | 메시지 보존 기간 (초) |
| `max_message_size` | `number` | `262144` | 최대 메시지 크기 (바이트) |
| `delay_seconds` | `number` | `0` | 메시지 전달 지연 시간 (초) |
| `receive_wait_time_seconds` | `number` | `20` | Long Polling 대기 시간 (초) |
| `max_receive_count` | `number` | `3` | DLQ 이동 전 최대 수신 횟수 |
| `dlq_message_retention_seconds` | `number` | `1209600` | DLQ 메시지 보존 기간 (초) |
| `fifo_queue` | `bool` | `false` | 메인 큐를 FIFO 큐로 생성 여부 |
| `enable_fifo_queue` | `bool` | `false` | 별도 FIFO 큐 추가 생성 여부 |
| `fifo_topic` | `bool` | `false` | SNS 토픽을 FIFO 토픽으로 생성 여부 |
| `content_based_deduplication` | `bool` | `false` | 콘텐츠 기반 중복 제거 여부 |
| `kms_master_key_id` | `string` | `null` | KMS 키 ID (null이면 SSE-SQS 사용) |
| `email_subscriptions` | `list(string)` | `[]` | 이메일 구독 목록 |
| `lambda_subscription_arns` | `list(string)` | `[]` | Lambda 구독 ARN 목록 |
| `https_subscription_urls` | `list(string)` | `[]` | HTTPS 구독 URL 목록 |
| `sqs_raw_message_delivery` | `bool` | `false` | Raw Message Delivery 여부 |
| `sns_filter_policy` | `string` | `""` | SNS 필터 정책 JSON |
| `enable_cloudwatch_alarms` | `bool` | `false` | CloudWatch 알람 활성화 여부 |
| `queue_depth_alarm_threshold` | `number` | `100` | 큐 깊이 알람 임계값 |
| `alarm_sns_topic_arns` | `list(string)` | `[]` | 알람 알림 SNS 토픽 ARN 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

## 모듈 출력값

| 출력값 | 설명 |
|---|---|
| `sns_topic_arn` | SNS 토픽 ARN |
| `sns_topic_name` | SNS 토픽 이름 |
| `main_queue_id` | 메인 SQS 큐 URL |
| `main_queue_arn` | 메인 SQS 큐 ARN |
| `main_queue_name` | 메인 SQS 큐 이름 |
| `main_queue_url` | 메인 SQS 큐 URL |
| `dlq_id` | DLQ URL |
| `dlq_arn` | DLQ ARN |
| `dlq_name` | DLQ 이름 |
| `fifo_queue_id` | FIFO 큐 URL (enable_fifo_queue = true 시) |
| `fifo_queue_arn` | FIFO 큐 ARN (enable_fifo_queue = true 시) |
| `queue_depth_alarm_arn` | 큐 깊이 알람 ARN |
| `dlq_depth_alarm_arn` | DLQ 깊이 알람 ARN |

---

## 사용 방법

### 1. 사전 준비

```bash
# Terraform 버전 확인 (1.5.0 이상 필요)
terraform version

# AWS 자격증명 설정
aws configure
# 또는 환경변수로 설정
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="ap-northeast-2"
```

### 2. 변수 파일 준비

```bash
# 환경별 tfvars 파일 수정
vi envs/dev/terraform.tfvars
```

### 3. Makefile을 이용한 배포

```bash
# 초기화
make init ENV=dev

# 변경 사항 미리보기
make plan ENV=dev

# 적용
make apply ENV=dev

# 출력값 확인
make output ENV=dev
```

---

## 고급 사용 예시

### SNS 필터 정책 적용

```hcl
module "sqs_sns" {
  source = "../../modules/sqs-sns"

  project_name = var.project_name
  environment  = "prod"
  queue_name   = "orders"
  topic_name   = "app-events"

  # 특정 이벤트 타입만 SQS 큐로 전달
  sns_filter_policy = jsonencode({
    event_type = ["order_placed", "payment_completed"]
  })
  sns_filter_policy_scope = "MessageAttributes"
}
```

### FIFO 큐 + KMS 암호화 (prod 권장)

```hcl
module "sqs_sns" {
  source = "../../modules/sqs-sns"

  project_name      = var.project_name
  environment       = "prod"
  queue_name        = "financial-transactions"
  topic_name        = "financial-events"

  # FIFO: 순서 보장 + 중복 제거
  enable_fifo_queue           = true
  content_based_deduplication = true

  # KMS 암호화 (고객 관리형 키)
  kms_master_key_id = "arn:aws:kms:ap-northeast-2:123456789012:key/..."

  # CloudWatch 알람
  enable_cloudwatch_alarms    = true
  queue_depth_alarm_threshold = 500
  alarm_sns_topic_arns        = ["arn:aws:sns:ap-northeast-2:123456789012:critical-alerts"]
}
```

---

## 요구사항

| 항목 | 버전 |
|---|---|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 (권장) |
| pre-commit | >= 3.0 (선택, 코드 품질 관리) |
| TFLint | >= 0.50 (선택, 정적 분석) |

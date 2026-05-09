# terraform-cloudwatch

재사용 가능한 AWS CloudWatch Terraform 모듈입니다.
로그 그룹, 메트릭 알람, 대시보드, SNS 알림을 통합 관리합니다.

## 모듈 구조

```
terraform-cloudwatch/
├── modules/
│   └── cloudwatch/
│       ├── main.tf        # 로그 그룹, 메트릭 알람, 대시보드, SNS
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (SNS ARN 등)
│
├── envs/
│   ├── dev/               # 개발 환경 (알람 비활성화)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (알람 활성화, 대시보드)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `kms_key_arn` | 로그 그룹 암호화 KMS 키 ARN | ❌ | `null` |
| `enable_alarm_notification` | 알람 알림 활성화 | ❌ | `false` |
| `alarm_email` | 알람 수신 이메일 | ❌ | `""` |
| `log_groups` | 생성할 로그 그룹 목록 | ❌ | `[]` |
| `metric_alarms` | 생성할 메트릭 알람 목록 | ❌ | `[]` |
| `enable_dashboard` | 대시보드 생성 여부 | ❌ | `false` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `sns_topic_arn` | 알람 알림 SNS 토픽 ARN |
| `log_group_names` | 생성된 로그 그룹 이름 목록 |

## 사용 방법

### 1. 환경 디렉토리로 이동

```bash
cd envs/dev   # 또는 envs/staging, envs/prod
```

### 2. 변수 파일 복사 및 편집

```bash
cp ../../terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집하여 실제 값 입력
```

### 3. 초기화 및 배포

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. 모듈 단독 사용 예시

```hcl
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name = "my-app"
  environment  = "prod"

  enable_alarm_notification = true
  alarm_email               = "infra@example.com"

  log_groups = [
    { name = "/app/my-app/api",    retention_days = 30 },
    { name = "/app/my-app/worker", retention_days = 14 },
  ]

  metric_alarms = [
    {
      alarm_name          = "high-cpu"
      description         = "EC2 CPU 80% 초과"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
    }
  ]

  enable_dashboard = true
  common_tags      = local.common_tags
}
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `enable_alarm_notification` | false | false | true |
| `enable_dashboard` | false | false | true |
| 로그 보존 기간 | 7일 | 14일 | 30일+ |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

# terraform-dynamodb

재사용 가능한 AWS DynamoDB Terraform 모듈입니다.
온디맨드/프로비저닝 빌링, GSI, PITR, 스트림, 자동 스케일링을 지원합니다.

## 모듈 구조

```
terraform-dynamodb/
├── modules/
│   └── dynamodb/
│       ├── main.tf        # DynamoDB 테이블, GSI, 자동 스케일링
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (테이블 이름, ARN 등)
│
├── envs/
│   ├── dev/               # 개발 환경 (PAY_PER_REQUEST, 삭제 보호 없음)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (삭제 보호, PITR 활성화)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `table_suffix` | 테이블 용도 접미사 (예: sessions) | ✅ | - |
| `hash_key` | 파티션 키 이름 (생성 후 변경 불가) | ✅ | - |
| `attributes` | 속성 정의 목록 (키에 사용하는 것만) | ✅ | - |
| `range_key` | 정렬 키 이름 | ❌ | `""` |
| `billing_mode` | PAY_PER_REQUEST / PROVISIONED | ❌ | `"PAY_PER_REQUEST"` |
| `deletion_protection` | 삭제 방지 (prod: true 권장) | ❌ | `false` |
| `enable_pitr` | Point-in-Time Recovery | ❌ | `false` |
| `enable_stream` | DynamoDB Streams 활성화 | ❌ | `false` |
| `ttl_attribute` | TTL 속성 이름 | ❌ | `""` |
| `kms_key_arn` | KMS 암호화 키 ARN | ❌ | `null` |
| `global_secondary_indexes` | GSI 정의 목록 | ❌ | `[]` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `table_name` | DynamoDB 테이블 이름 |
| `table_arn` | DynamoDB 테이블 ARN |
| `stream_arn` | DynamoDB Streams ARN (enable_stream=true 시) |

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
module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name = "my-app"
  environment  = "prod"
  table_suffix = "sessions"

  hash_key  = "session_id"
  range_key = "created_at"

  attributes = [
    { name = "session_id", type = "S" },
    { name = "created_at", type = "S" },
    { name = "user_id",    type = "S" },
  ]

  global_secondary_indexes = [
    {
      name            = "user-index"
      hash_key        = "user_id"
      projection_type = "ALL"
    }
  ]

  deletion_protection = true   # prod
  enable_pitr         = true   # prod
  ttl_attribute       = "expires_at"

  common_tags = local.common_tags
}
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `billing_mode` | PAY_PER_REQUEST | PAY_PER_REQUEST | PROVISIONED |
| `deletion_protection` | false | false | true |
| `enable_pitr` | false | false | true |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

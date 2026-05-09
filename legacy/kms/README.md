# terraform-kms

재사용 가능한 AWS KMS(Key Management Service) Terraform 모듈입니다.
자동 키 교체, 멀티 리전 키, 커스텀 키 정책을 지원합니다.

## 모듈 구조

```
terraform-kms/
├── modules/
│   └── kms/
│       ├── main.tf        # KMS 키, 키 별칭
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (키 ARN, 별칭 ARN 등)
│
├── envs/
│   ├── dev/               # 개발 환경 (삭제 대기 7일)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (삭제 대기 30일, 키 교체 활성화)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `key_suffix` | 키 용도 접미사 (예: rds, s3, eks) | ✅ | - |
| `key_alias` | 키 별칭 직접 지정 | ❌ | `null` (자동생성) |
| `key_usage` | ENCRYPT_DECRYPT / SIGN_VERIFY | ❌ | `"ENCRYPT_DECRYPT"` |
| `key_spec` | SYMMETRIC_DEFAULT / RSA_2048 등 | ❌ | `"SYMMETRIC_DEFAULT"` |
| `deletion_window_in_days` | 삭제 대기 기간 (7~30일) | ❌ | `30` |
| `enable_key_rotation` | 자동 키 교체 활성화 | ❌ | `true` |
| `multi_region` | 멀티 리전 키 활성화 | ❌ | `false` |
| `key_policy_json` | 커스텀 키 정책 JSON | ❌ | `""` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `key_id` | KMS 키 ID |
| `key_arn` | KMS 키 ARN (다른 모듈에서 참조) |
| `alias_name` | KMS 키 별칭 |
| `alias_arn` | KMS 키 별칭 ARN |

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
module "kms" {
  source = "../../modules/kms"

  project_name = "my-app"
  environment  = "prod"
  key_suffix   = "rds"

  enable_key_rotation     = true
  deletion_window_in_days = 30

  common_tags = local.common_tags
}

# 다른 모듈에서 KMS 키 참조
module "rds" {
  source      = "../rds"
  kms_key_arn = module.kms.key_arn
}
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `deletion_window_in_days` | 7 | 14 | 30 |
| `enable_key_rotation` | true | true | true |
| `multi_region` | false | false | DR 필요 시 true |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

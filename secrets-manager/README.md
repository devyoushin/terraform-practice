# terraform-secrets-manager

재사용 가능한 AWS Secrets Manager Terraform 모듈입니다.
시크릿 생성, KMS 암호화, 자동 교체(Lambda), 접근 정책을 지원합니다.

## 모듈 구조

```
terraform-secrets-manager/
├── modules/
│   └── secrets-manager/
│       ├── main.tf        # Secrets Manager 시크릿, 자동 교체
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (시크릿 ARN 등)
│
├── envs/
│   ├── dev/               # 개발 환경 (즉시 삭제, 교체 없음)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (복구 대기 30일, KMS 암호화)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `secret_suffix` | 시크릿 용도 접미사 (예: rds, api-key) | ✅ | - |
| `secret_name` | 시크릿 이름 직접 지정 | ❌ | `null` (자동생성) |
| `description` | 시크릿 설명 | ❌ | `""` |
| `kms_key_arn` | KMS 키 ARN | ❌ | `null` |
| `recovery_window_in_days` | 삭제 복구 대기 기간 (0=즉시) | ❌ | `30` |
| `enable_rotation` | 자동 교체 활성화 | ❌ | `false` |
| `rotation_lambda_arn` | 교체 Lambda ARN | ❌ | `""` |
| `rotation_days` | 교체 주기 (일) | ❌ | `30` |
| `secret_policy_json` | 접근 정책 JSON | ❌ | `""` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `secret_arn` | Secrets Manager 시크릿 ARN |
| `secret_name` | 시크릿 이름 |
| `secret_id` | 시크릿 ID |

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

### 4. 시크릿 값 설정 (배포 후 CLI로 직접)

```bash
aws secretsmanager put-secret-value \
  --secret-id $(terraform output -raw secret_name) \
  --secret-string '{"username":"admin","password":"CHANGE_ME"}' \
  --region ap-northeast-2
```

### 5. 모듈 단독 사용 예시

```hcl
module "rds_secret" {
  source = "../../modules/secrets-manager"

  project_name  = "my-app"
  environment   = "prod"
  secret_suffix = "rds"
  description   = "RDS 마스터 계정 정보"

  kms_key_arn             = module.kms.key_arn
  recovery_window_in_days = 30

  common_tags = local.common_tags
}
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `recovery_window_in_days` | 0 | 7 | 30 |
| `kms_key_arn` | null | null | 필수 |
| `enable_rotation` | false | false | true (권장) |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

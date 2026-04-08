# Terraform S3 모듈

재사용 가능한 AWS S3 버킷 관리 Terraform 모듈입니다. 환경별(dev/staging/prod) 분리 구성을 통해 안전하고 일관된 S3 버킷 관리를 제공합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| 버전관리 | 객체 버전 보존으로 실수로 삭제된 파일 복구 가능 |
| 서버 사이드 암호화 | 기본 AES256(S3 관리형 키) 또는 KMS 고객 관리형 키 선택 적용 |
| 퍼블릭 액세스 차단 | 모든 환경에서 퍼블릭 액세스 강제 차단 (4가지 옵션 모두 적용) |
| 수명주기 규칙 | 이전 버전 자동 전환(30일→STANDARD_IA) 및 삭제(90일), 미완성 멀티파트 정리(7일) |
| CORS 설정 | dynamic block으로 복수의 CORS 규칙 유연하게 적용 |
| 버킷 정책 | JSON 형식의 IAM 버킷 정책 주입 지원 |

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| `force_destroy` | `true` (삭제 편의) | `false` | `false` (절대 변경 금지) |
| `enable_versioning` (assets) | `false` | `true` | `true` |
| `enable_versioning` (logs) | `false` | `false` | `false` |
| `enable_lifecycle` (logs) | `true` | `true` | `true` |
| backup 버킷 | 주석 처리 (선택) | 없음 | `true` (버전관리 + 수명주기) |
| 암호화 | AES256 | AES256 | AES256 (KMS 적용 가능) |

---

## 디렉토리 구조

```
terraform-s3/
├── modules/s3/           # 재사용 가능한 S3 모듈
│   ├── main.tf           # S3 버킷 및 관련 리소스 정의
│   ├── variables.tf      # 모듈 입력 변수
│   └── outputs.tf        # 모듈 출력값
├── envs/
│   ├── dev/              # 개발 환경
│   ├── staging/          # 스테이징 환경
│   └── prod/             # 운영 환경
├── Makefile              # 환경별 작업 자동화
├── .pre-commit-config.yaml
├── .gitignore
└── terraform.tfvars.example
```

---

## 버킷 명명 규칙

버킷 이름은 아래 패턴으로 자동 생성됩니다.

```
{project_name}-{environment}-{bucket_suffix}
```

예시:

| project_name | environment | bucket_suffix | 생성되는 버킷 이름 |
|---|---|---|---|
| `my-project` | `dev` | `assets` | `my-project-dev-assets` |
| `my-project` | `prod` | `logs` | `my-project-prod-logs` |
| `my-company` | `prod` | `tfstate` | `my-company-prod-tfstate` |

`bucket_name` 변수를 직접 지정하면 자동 생성 규칙을 무시하고 해당 이름을 사용합니다.

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 (버킷 이름 자동 생성에 사용) |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `bucket_suffix` | `string` | 필수 | 버킷 용도 (예: `assets`, `logs`, `backup`) |
| `bucket_name` | `string` | `null` | 버킷 이름 직접 지정 (null이면 자동 생성) |
| `force_destroy` | `bool` | `false` | 내용 있어도 강제 삭제 허용 여부 |
| `enable_versioning` | `bool` | `true` | 버킷 버전관리 활성화 여부 |
| `kms_key_arn` | `string` | `null` | KMS 키 ARN (null이면 AES256 사용) |
| `enable_lifecycle` | `bool` | `false` | 수명주기 규칙 활성화 여부 |
| `bucket_policy_json` | `string` | `""` | 버킷 정책 JSON 문자열 |
| `cors_rules` | `list(object)` | `[]` | CORS 규칙 목록 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

## 모듈 출력값

| 출력값 | 설명 |
|---|---|
| `bucket_id` | S3 버킷 이름 |
| `bucket_arn` | S3 버킷 ARN |
| `bucket_domain_name` | 글로벌 도메인 이름 |
| `bucket_regional_domain_name` | 리전별 도메인 이름 (CloudFront 권장) |
| `bucket_region` | 버킷이 생성된 AWS 리전 |

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
# 예시 파일을 복사하여 실제 환경에 맞게 수정
cp terraform.tfvars.example envs/dev/terraform.tfvars
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

### 4. Terraform 직접 실행

```bash
cd envs/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

---

## 고급 사용 예시

### CORS 설정 (웹 앱에서 S3 직접 업로드)

```hcl
module "assets_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "assets"

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["https://my-app.com", "https://www.my-app.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}
```

### 버킷 정책 JSON 주입

```hcl
module "assets_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "assets"

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::my-project-prod-assets/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::123456789012:distribution/ABCDEFG"
          }
        }
      }
    ]
  })
}
```

### KMS 암호화 적용

```hcl
module "backup_bucket" {
  source = "../../modules/s3"

  project_name  = var.project_name
  environment   = "prod"
  bucket_suffix = "backup"

  # 고객 관리형 KMS 키로 암호화
  kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

---

## Terraform 상태 파일 저장용 S3 버킷 생성 예시

다른 프로젝트들의 `backend.tf`에서 사용할 tfstate 저장 버킷을 이 모듈로 생성할 수 있습니다.

```hcl
# 최초 1회는 local backend로 배포 후, S3 backend로 마이그레이션하는 것을 권장합니다.
module "tfstate_bucket" {
  source        = "../../modules/s3"
  project_name  = "my-company"
  environment   = "prod"
  bucket_suffix = "tfstate"

  enable_versioning = true   # 상태 파일은 버전관리 필수 (실수로 인한 손상 복구)
  force_destroy     = false  # 상태 파일 버킷은 절대 강제 삭제 금지
  enable_lifecycle  = true   # 오래된 상태 파일 버전 자동 정리
}
```

생성 후 각 환경의 `backend.tf`에서 아래와 같이 참조합니다.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-prod-tfstate"
    key            = "prod/s3/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

> **참고**: DynamoDB 상태 잠금 테이블은 파티션 키를 `LockID`(String 타입)로 설정하여 별도 생성해야 합니다.

---

## 요구사항

| 항목 | 버전 |
|---|---|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 (권장) |
| pre-commit | >= 3.0 (선택, 코드 품질 관리) |
| TFLint | >= 0.50 (선택, 정적 분석) |

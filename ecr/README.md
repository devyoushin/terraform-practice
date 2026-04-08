# terraform-ecr

재사용 가능한 AWS ECR(Elastic Container Registry) Terraform 모듈입니다.
이미지 수명주기 정책, 취약점 스캔, KMS 암호화를 지원합니다.

## 모듈 구조

```
terraform-ecr/
├── modules/
│   └── ecr/
│       ├── main.tf        # ECR 레포지토리, 수명주기 정책, 레포지토리 정책
│       ├── variables.tf   # 입력 변수 정의
│       ├── outputs.tf     # 출력값 (레포지토리 URL 등)
│       └── versions.tf    # Provider 버전 고정
│
├── envs/
│   ├── dev/               # 개발 환경 (MUTABLE, force_delete 허용)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (IMMUTABLE, 크로스 계정 접근 가능)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `name_suffix` | 레포지토리 접미사 (예: app, api) | ✅ | - |
| `repository_name` | 레포지토리 이름 직접 지정 | ❌ | `null` (자동생성) |
| `image_tag_mutability` | MUTABLE / IMMUTABLE | ❌ | `"MUTABLE"` |
| `scan_on_push` | 푸시 시 취약점 스캔 | ❌ | `true` |
| `force_delete` | 이미지 있어도 강제 삭제 | ❌ | `false` |
| `encryption_type` | AES256 / KMS | ❌ | `"AES256"` |
| `kms_key_arn` | KMS 키 ARN | ❌ | `null` |
| `enable_lifecycle_policy` | 수명주기 정책 활성화 | ❌ | `true` |
| `untagged_image_days` | 태그 없는 이미지 보존 일수 | ❌ | `14` |
| `tagged_image_count` | 태그 있는 이미지 최대 보존 수 | ❌ | `30` |
| `repository_policy_json` | 레포지토리 접근 정책 JSON | ❌ | `""` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `repository_url` | ECR 레포지토리 URL (docker push 시 사용) |
| `repository_arn` | ECR 레포지토리 ARN |
| `repository_name` | ECR 레포지토리 이름 |

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

### 4. Docker 이미지 푸시 예시

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw repository_url | cut -d/ -f1)

# 이미지 태그 & 푸시
docker tag my-app:latest $(terraform output -raw repository_url):latest
docker push $(terraform output -raw repository_url):latest
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `image_tag_mutability` | MUTABLE | MUTABLE | IMMUTABLE |
| `force_delete` | true | false | false |
| `tagged_image_count` | 10 | 20 | 30 |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

# terraform-cloudfront

재사용 가능한 AWS CloudFront Terraform 모듈입니다.
S3 정적 파일 서빙 및 ALB(API) 프록시를 OAC(Origin Access Control) 기반으로 구성합니다.

## 아키텍처

```
사용자
  │
  ▼
CloudFront Distribution
  ├── S3 Origin (OAC) ──► S3 버킷 (정적 파일)
  └── ALB Origin       ──► ALB ──► EC2/ECS
```

**환경별 특이사항:**
- `dev/staging`: WAF 미연결, 액세스 로그 비활성화 (비용 절감)
- `prod`: WAF 연결, 액세스 로그 활성화, IMMUTABLE 태그, 커스텀 도메인

## 모듈 구조

```
terraform-cloudfront/
├── modules/
│   └── cloudfront/
│       ├── main.tf        # CloudFront 배포, OAC, WAF 연결
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (배포 ID, 도메인 등)
│
├── envs/
│   ├── dev/               # 개발 환경
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (커스텀 도메인, WAF)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `s3_origin_bucket_domain` | S3 오리진 버킷 도메인 | ❌ | `""` |
| `alb_origin_domain` | ALB 오리진 도메인 | ❌ | `""` |
| `default_root_object` | 루트 URL 기본 객체 | ❌ | `"index.html"` |
| `aliases` | 커스텀 도메인 목록 | ❌ | `[]` |
| `acm_certificate_arn` | ACM 인증서 ARN (us-east-1) | ❌ | `""` |
| `price_class` | 엣지 로케이션 범위 | ❌ | `"PriceClass_200"` |
| `web_acl_id` | WAF Web ACL ID | ❌ | `""` |
| `access_log_bucket` | 액세스 로그 S3 버킷 | ❌ | `""` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `distribution_id` | CloudFront 배포 ID (캐시 무효화 시 사용) |
| `distribution_arn` | CloudFront 배포 ARN |
| `domain_name` | CloudFront 도메인 (예: d1234.cloudfront.net) |
| `hosted_zone_id` | Route53 Alias 설정 시 사용 (고정값) |
| `oac_id` | S3 버킷 정책 설정 시 사용하는 OAC ID |

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

### 4. 캐시 무효화 예시

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw distribution_id) \
  --paths "/*"
```

### 5. 모듈 단독 사용 예시

```hcl
module "cdn" {
  source = "../../modules/cloudfront"

  project_name = "my-app"
  environment  = "prod"

  s3_origin_bucket_domain = module.s3.bucket_regional_domain_name
  default_root_object      = "index.html"

  aliases             = ["cdn.example.com"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"

  web_acl_id        = module.waf.web_acl_arn
  access_log_bucket = "my-app-cloudfront-logs"

  common_tags = local.common_tags
}
```

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

> **주의:** ACM 인증서는 반드시 `us-east-1` 리전에서 발급해야 합니다.

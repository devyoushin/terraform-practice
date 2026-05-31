# terraform-waf

재사용 가능한 AWS WAF v2 Terraform 모듈입니다.
AWS 관리형 규칙, IP 기반 Rate Limiting, IP 차단/허용 목록을 지원합니다.

## 아키텍처

```
인터넷
  │
  ▼
WAF Web ACL
  ├── IP 차단 목록 (블랙리스트)
  ├── IP 허용 목록 (화이트리스트, default_action=block 시)
  ├── Rate Limiting (IP별 요청 수 제한)
  ├── AWS 관리형 규칙 (AWSManagedRulesCommonRuleSet 등)
  └── 기본 동작 (allow / block)
  │
  ▼
ALB 또는 CloudFront
```

## 모듈 구조

```
terraform-waf/
├── modules/
│   └── waf/
│       ├── main.tf        # Web ACL, IP Set, 규칙, ALB 연결
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (Web ACL ID, ARN)
│
├── envs/
│   ├── dev/               # 개발 환경 (count 모드 - 모니터링만)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (실제 차단, Rate Limiting)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `scope` | REGIONAL / CLOUDFRONT | ❌ | `"REGIONAL"` |
| `default_action` | allow / block | ❌ | `"allow"` |
| `managed_rules_action` | none(차단) / count(모니터링) | ❌ | `"none"` |
| `enable_rate_limiting` | IP 요청 수 제한 활성화 | ❌ | `true` |
| `rate_limit` | 5분당 IP별 최대 요청 수 | ❌ | `2000` |
| `blocked_ip_addresses` | 차단 IP 목록 (CIDR) | ❌ | `[]` |
| `allowed_ip_addresses` | 허용 IP 목록 (CIDR) | ❌ | `[]` |
| `resource_arn` | 연결할 ALB ARN | ❌ | `""` |
| `log_destination_arn` | 로그 대상 ARN | ❌ | `""` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `web_acl_id` | WAF Web ACL ID |
| `web_acl_arn` | WAF Web ACL ARN (CloudFront/ALB 연결 시 사용) |

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
module "waf" {
  source = "../../modules/waf"

  project_name         = "my-app"
  environment          = "prod"
  scope                = "REGIONAL"
  managed_rules_action = "none"   # 실제 차단
  enable_rate_limiting = true
  rate_limit           = 2000
  resource_arn         = module.alb.alb_arn

  common_tags = local.common_tags
}

# CloudFront에 WAF 연결 시
module "cdn" {
  source     = "../cloudfront"
  web_acl_id = module.waf.web_acl_arn
}
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `managed_rules_action` | count | count | none |
| `enable_rate_limiting` | false | true | true |
| `rate_limit` | - | 5000 | 2000 |

> **주의:** CloudFront용 WAF는 반드시 `us-east-1` 리전에서 생성해야 합니다.

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

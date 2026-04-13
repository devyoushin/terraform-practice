# Terraform Route53 모듈

재사용 가능한 AWS Route53 DNS 관리 Terraform 모듈입니다. 환경별(dev/staging/prod) 분리 구성을 통해 안전하고 일관된 DNS 인프라를 제공합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| 퍼블릭 호스팅 존 | 신규 생성 또는 기존 존 참조(data source) 선택 |
| 프라이빗 호스팅 존 | 선택적 생성, VPC 연결, 내부 서비스 디스커버리 지원 |
| DNS 레코드 | A, CNAME, MX, TXT, NS 등 모든 타입, alias(ALB/CloudFront/S3) 지원 |
| 헬스 체크 | HTTP/HTTPS 엔드포인트 상태 모니터링, 다중 리전 체크 지원 |
| 페일오버 라우팅 | Primary/Secondary 자동 전환, 헬스 체크 연동 |
| CloudWatch 알람 | 헬스 체크 실패 시 즉각 알림 (us-east-1 리전에 생성) |
| Route53 Resolver | Outbound Endpoint + Forward Rule로 하이브리드 DNS 지원 |

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| 호스팅 존 | 서브도메인 신규 생성 | 서브도메인 신규 생성 | 루트 도메인 생성/참조 |
| 프라이빗 존 | 비활성화 | 선택적 | 선택적 |
| 헬스 체크 | 비활성화 | 활성화 | 활성화 (필수) |
| 페일오버 라우팅 | 비활성화 | 비활성화 | 활성화 권장 |
| CloudWatch 알람 | 비활성화 | 활성화 (헬스 체크 시) | 활성화 (필수) |
| Route53 Resolver | 비활성화 | 선택적 | 선택적 |

---

## 디렉토리 구조

```
route53/
├── modules/route53/      # 재사용 가능한 Route53 모듈
│   ├── main.tf           # 호스팅 존, 레코드, 헬스 체크, 페일오버, Resolver 정의
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

## 중요 사항

### CloudWatch 헬스 체크 알람은 반드시 us-east-1에서 생성

Route53 헬스 체크 메트릭(`AWS/Route53` 네임스페이스)은 글로벌 서비스이므로 CloudWatch 알람이 `us-east-1` 리전에만 존재합니다. 이 모듈은 `aws.us_east_1` provider alias를 사용하여 자동으로 처리합니다.

```hcl
# 모든 환경의 main.tf에서 us-east-1 provider 선언 필수
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

### 알람 SNS 토픽도 us-east-1 리전에 있어야 합니다

```
alarm_sns_topic_arns = ["arn:aws:sns:us-east-1:123456789012:prod-alerts"]
```

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `zone_name` | `string` | 필수 | 호스팅 존 도메인 이름 |
| `aws_region` | `string` | `ap-northeast-2` | AWS 리전 |
| `create_zone` | `bool` | `true` | 신규 생성 여부 (false이면 기존 존 참조) |
| `zone_comment` | `string` | `""` | 호스팅 존 설명 |
| `enable_private_zone` | `bool` | `false` | 프라이빗 존 생성 여부 |
| `private_zone_name` | `string` | `""` | 프라이빗 존 도메인 |
| `private_zone_vpc_ids` | `list(string)` | `[]` | 프라이빗 존 연결 VPC 목록 |
| `records` | `map(object)` | `{}` | 퍼블릭 존 DNS 레코드 맵 |
| `private_records` | `map(object)` | `{}` | 프라이빗 존 DNS 레코드 맵 |
| `enable_health_checks` | `bool` | `false` | 헬스 체크 활성화 |
| `health_checks` | `map(object)` | `{}` | 헬스 체크 설정 맵 |
| `enable_failover_routing` | `bool` | `false` | 페일오버 라우팅 활성화 |
| `failover_records` | `map(object)` | `{}` | 페일오버 레코드 맵 |
| `enable_health_check_alarms` | `bool` | `false` | CloudWatch 알람 활성화 |
| `alarm_sns_topic_arns` | `list(string)` | `[]` | 알람 SNS 토픽 ARN 목록 |
| `enable_resolver` | `bool` | `false` | Route53 Resolver 활성화 |
| `resolver_security_group_ids` | `list(string)` | `[]` | Resolver 보안 그룹 목록 |
| `resolver_subnet_ids` | `list(string)` | `[]` | Resolver 서브넷 목록 |
| `resolver_vpc_id` | `string` | `""` | Resolver VPC ID |
| `resolver_rules` | `map(object)` | `{}` | DNS 포워딩 규칙 맵 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

## 모듈 출력값

| 출력값 | 설명 |
|---|---|
| `zone_id` | 퍼블릭 호스팅 존 ID |
| `zone_name_servers` | 네임서버 목록 (도메인 등록 기관 등록 필요) |
| `zone_arn` | 퍼블릭 호스팅 존 ARN |
| `zone_name` | 호스팅 존 도메인 이름 |
| `private_zone_id` | 프라이빗 호스팅 존 ID |
| `record_fqdns` | 생성된 DNS 레코드 FQDN 맵 |
| `private_record_fqdns` | 프라이빗 존 레코드 FQDN 맵 |
| `health_check_ids` | 헬스 체크 ID 맵 |
| `failover_primary_fqdns` | 페일오버 Primary 레코드 FQDN 맵 |
| `failover_secondary_fqdns` | 페일오버 Secondary 레코드 FQDN 맵 |
| `resolver_endpoint_id` | Resolver Endpoint ID |
| `resolver_rule_ids` | Resolver Rule ID 맵 |

---

## 사용 방법

### 1. 사전 준비

```bash
# Terraform 버전 확인 (1.5.0 이상 필요)
terraform version

# AWS 자격증명 설정
aws configure
```

### 2. 변수 파일 준비

```bash
# 환경별 tfvars 파일 수정
vi envs/prod/terraform.tfvars
```

### 3. Makefile을 이용한 배포

```bash
# 초기화
make init ENV=prod

# 변경 사항 미리보기
make plan ENV=prod

# 적용
make apply ENV=prod

# 출력값 확인 (네임서버 확인 시 사용)
make output ENV=prod
```

---

## 고급 사용 예시

### ALB alias + 헬스 체크 + 페일오버 라우팅 (prod 권장)

```hcl
module "route53" {
  source = "../../modules/route53"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = "prod"
  zone_name    = "example.com"

  enable_health_checks = true
  health_checks = {
    api_primary = {
      fqdn          = "api-primary.example.com"
      port          = 443
      type          = "HTTPS"
      resource_path = "/health"
    }
    api_secondary = {
      fqdn          = "api-secondary.example.com"
      port          = 443
      type          = "HTTPS"
      resource_path = "/health"
    }
  }

  enable_failover_routing = true
  failover_records = {
    api = {
      name = "api"
      type = "A"
      primary_alias = {
        name                   = "primary-alb.ap-northeast-2.elb.amazonaws.com"
        zone_id                = "ZWKZPGTI48KDX"
        evaluate_target_health = true
      }
      secondary_alias = {
        name                   = "secondary-alb.ap-northeast-2.elb.amazonaws.com"
        zone_id                = "ZWKZPGTI48KDX"
        evaluate_target_health = true
      }
      primary_health_check_key   = "api_primary"
      secondary_health_check_key = "api_secondary"
    }
  }

  enable_health_check_alarms = true
  alarm_sns_topic_arns       = ["arn:aws:sns:us-east-1:123456789012:prod-alerts"]
}
```

### 하이브리드 DNS (Route53 Resolver)

```hcl
module "route53" {
  source = "../../modules/route53"

  # ...기본 설정...

  enable_resolver             = true
  resolver_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]
  resolver_subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  resolver_vpc_id             = "vpc-xxxxxxxxxxxxxxxxx"

  resolver_rules = {
    corp_internal = {
      domain_name = "corp.internal"
      target_ips = [
        { ip = "10.0.1.10", port = 53 },
        { ip = "10.0.2.10", port = 53 },
      ]
    }
  }
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

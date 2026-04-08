# terraform-alb

AWS Application Load Balancer(ALB) + ACM + HTTPS 리다이렉트를 Terraform으로 관리하는 모듈입니다.
환경별(dev / staging / prod) 설정 분리와 재사용 가능한 모듈 구조를 제공합니다.

---

## 아키텍처

```
Internet → [ALB SG] → [ALB]
                         ├── HTTP:80  → Redirect 301 → HTTPS:443
                         └── HTTPS:443 → [Target Group] → EC2/ECS/EKS
```

### 환경별 구성 비교

| 항목                    | dev          | staging          | prod                  |
|-------------------------|--------------|------------------|-----------------------|
| ALB 유형                | 퍼블릭       | 퍼블릭           | 퍼블릭                |
| HTTP 리스너 (80)        | 포워딩       | 포워딩           | HTTPS 리다이렉트      |
| HTTPS 리스너 (443)      | 없음         | 없음 (선택 가능) | 필수                  |
| ACM 인증서              | 불필요       | 선택             | 필수 (기존 ARN 입력)  |
| 삭제 보호               | 비활성화     | 비활성화         | 활성화                |
| 액세스 로그             | 비활성화     | 비활성화         | S3 저장 활성화        |
| 가용영역 (서브넷 수)    | 2개 이상     | 2개 이상         | 3개 이상 권장         |

---

## 디렉토리 구조

```
terraform-alb/
├── modules/alb/           # 재사용 가능한 ALB 모듈
│   ├── main.tf            # 리소스 정의 (SG, ALB, TG, 리스너)
│   ├── variables.tf       # 입력 변수
│   └── outputs.tf         # 출력값
├── envs/
│   ├── dev/               # 개발 환경 (HTTP만)
│   ├── staging/           # 스테이징 환경 (HTTP 기본, HTTPS 선택)
│   └── prod/              # 운영 환경 (HTTPS 강제)
├── Makefile               # 환경별 Terraform 명령어 단축키
├── terraform.tfvars.example
├── .gitignore
└── .pre-commit-config.yaml
```

---

## 모듈 변수 (modules/alb/variables.tf)

| 변수명                    | 타입          | 기본값       | 설명                                               |
|---------------------------|---------------|--------------|---------------------------------------------------|
| `project_name`            | string        | 필수         | 프로젝트 이름 (리소스 네이밍에 사용)              |
| `environment`             | string        | 필수         | 배포 환경 (dev / staging / prod)                  |
| `vpc_id`                  | string        | 필수         | ALB를 생성할 VPC ID                               |
| `subnet_ids`              | list(string)  | 필수         | 배치할 서브넷 ID 목록 (최소 2개)                  |
| `internal`                | bool          | `false`      | 내부 ALB 여부 (false: 퍼블릭)                     |
| `enable_deletion_protection` | bool       | `false`      | ALB 삭제 보호 (prod 권장)                         |
| `target_type`             | string        | `"instance"` | 타겟 그룹 타입 (instance/ip/lambda)               |
| `health_check_path`       | string        | `"/"`        | 헬스체크 경로                                     |
| `health_check_matcher`    | string        | `"200"`      | 헬스체크 정상 응답 상태 코드                      |
| `enable_https_redirect`   | bool          | `true`       | HTTP → HTTPS 301 리다이렉트 활성화                |
| `create_https_listener`   | bool          | `false`      | HTTPS(443) 리스너 생성 여부                       |
| `acm_certificate_arn`     | string        | `null`       | 기존 ACM 인증서 ARN                               |
| `create_acm_certificate`  | bool          | `false`      | 모듈 내 ACM 인증서 신규 발급 여부                 |
| `domain_name`             | string        | `null`       | ACM 인증서 도메인 (create_acm_certificate 시 필수)|
| `enable_access_logs`      | bool          | `false`      | 액세스 로그 S3 저장 활성화                        |
| `access_logs_bucket`      | string        | `null`       | 액세스 로그 S3 버킷 이름                          |
| `common_tags`             | map(string)   | `{}`         | 모든 리소스에 공통 적용할 태그                    |

---

## 모듈 출력값 (modules/alb/outputs.tf)

| 출력값명             | 설명                                         |
|----------------------|----------------------------------------------|
| `alb_id`             | ALB ID                                       |
| `alb_arn`            | ALB ARN                                      |
| `alb_dns_name`       | ALB DNS 이름 (Route53 연동에 사용)           |
| `alb_zone_id`        | ALB Hosted Zone ID (Route53 alias용)         |
| `target_group_arn`   | 타겟 그룹 ARN                                |
| `target_group_name`  | 타겟 그룹 이름                               |
| `security_group_id`  | ALB 보안 그룹 ID                             |
| `http_listener_arn`  | HTTP(80) 리스너 ARN                          |
| `https_listener_arn` | HTTPS(443) 리스너 ARN (미생성 시 null)       |

---

## 사용 방법

### 1. 사전 준비

- Terraform >= 1.5.0 설치
- AWS CLI 설정 (`aws configure` 또는 환경변수)
- 대상 VPC 및 서브넷 ID 확인

### 2. 환경별 배포

```bash
# dev 환경 배포
make init-dev
make plan-dev
make apply-dev

# staging 환경 배포
make init-staging
make plan-staging
make apply-staging

# prod 환경 배포 (acm_certificate_arn 필수 입력 후 실행)
make init-prod
make plan-prod
make apply-prod
```

### 3. terraform.tfvars 설정

각 환경 디렉토리의 `terraform.tfvars` 파일에서 실제 값으로 변경하세요.

```bash
cp terraform.tfvars.example envs/dev/terraform.tfvars
# 파일 편집 후 배포
```

### 4. 원격 백엔드 활성화 (팀 협업 시 권장)

각 환경의 `backend.tf` 파일에서 주석을 해제하고 버킷 이름을 수정하세요.

---

## Route53 연동 예시

ALB DNS 이름을 Route53 도메인에 연결하는 예시입니다.

```hcl
resource "aws_route53_record" "app" {
  zone_id = "YOUR_ZONE_ID"
  name    = "app.example.com"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
```

---

## ACM 인증서 발급 방법

### 방법 1: 기존 인증서 ARN 사용 (권장)

AWS 콘솔 또는 CLI로 인증서를 미리 발급한 후 ARN을 입력합니다.

```hcl
acm_certificate_arn = "arn:aws:acm:ap-northeast-2:123456789012:certificate/XXXX"
```

### 방법 2: 모듈 내 신규 발급

```hcl
create_acm_certificate = true
domain_name            = "app.example.com"
```

발급 후 Route53에서 DNS 검증 레코드를 생성해야 합니다.

---

## 요구사항

| 항목         | 버전/조건                         |
|--------------|-----------------------------------|
| Terraform    | >= 1.5.0                          |
| AWS Provider | ~> 5.0                            |
| AWS 권한     | ALB, ACM, EC2(SG) 생성/수정 권한 |
| 서브넷       | 최소 2개 (서로 다른 가용영역)     |
| prod HTTPS   | ACM 인증서 ARN 필수               |

# AWS Transit Gateway Terraform Module

프로덕션 환경에서 사용 가능한 AWS Transit Gateway Terraform 모듈입니다.
Hub-and-Spoke 아키텍처를 기반으로 멀티 VPC, 멀티 어카운트 네트워크 환경을 지원합니다.

## 아키텍처

```
                         ┌─────────────────────────────────┐
                         │        Transit Gateway          │
                         │                                 │
              ┌──────────┤  RT: shared  RT: prod  RT: dev  ├──────────┐
              │          └──────┬───────────┬─────────┬────┘          │
              │                 │           │         │               │
       [Shared VPC]       [Egress VPC]  [Prod VPC] [Dev VPC]    [On-Prem/VPN]
       (Hub: 공유서비스)       (인터넷 출구)   (Spoke)    (Spoke)
```

**라우팅 정책:**
- Prod/Dev → Shared VPC 통신 ✅
- Shared VPC → Prod/Dev 통신 ✅
- Prod ↔ Dev 직접 통신 ❌ (블랙홀 라우트)
- Prod/Dev 인터넷 트래픽 → Egress VPC 경유

## 모듈 구조

```
terraform-tgw/
├── main.tf                        # 루트 모듈 (오케스트레이션)
├── variables.tf                   # 입력 변수 정의
├── outputs.tf                     # 출력값 정의
├── versions.tf                    # 프로바이더 버전 제약
├── terraform.tfvars.example       # 변수 예시 파일
│
├── modules/
│   ├── transit-gateway/           # TGW 코어 리소스
│   ├── tgw-route-table/           # TGW 라우트 테이블
│   ├── tgw-vpc-attachment/        # VPC → TGW 어태치먼트
│   ├── tgw-vpn/                   # Site-to-Site VPN 연결
│   └── tgw-ram/                   # RAM 멀티어카운트 공유
│
├── env/
│   ├── dev/                       # DEV 환경 설정
│   └── prod/                      # PROD 환경 설정
│
└── examples/
    └── hub-and-spoke/             # Hub-and-Spoke 완성 예시
```

## 주요 기능

| 기능 | 설명 |
|------|------|
| **라우트 테이블 분리** | VPC 유형별 독립 라우트 테이블 (격리/보안) |
| **블랙홀 라우트** | 특정 VPC 간 통신 명시적 차단 |
| **BGP/ECMP** | Site-to-Site VPN 고가용성 지원 |
| **Appliance Mode** | 방화벽/NVA 삽입 지원 |
| **RAM 공유** | 멀티 어카운트 TGW 공유 |
| **VPN 로깅** | CloudWatch 터널 로그 수집 |
| **자동 VPC 라우팅** | VPC 라우트 테이블에 TGW 경로 자동 추가 |

## 사용 방법

### 1. 변수 파일 준비

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집하여 실제 값 입력
```

### 2. 초기화 및 배포

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. 루트 모듈로 직접 사용

```hcl
module "tgw" {
  source = "git::https://github.com/your-org/terraform-tgw.git?ref=v1.0.0"

  project     = "mycompany"
  environment = "prod"

  tgw_route_tables = {
    prod   = { name = "rt-prod" }
    shared = { name = "rt-shared" }
  }

  vpc_attachments = {
    prod = {
      vpc_id          = "vpc-xxxxxxxx"
      subnet_ids      = ["subnet-aaa", "subnet-bbb"]
      route_table_key = "prod"
    }
  }

  tgw_route_table_propagations = {
    shared_from_prod = { route_table_key = "shared", attachment_key = "prod" }
  }
}
```

## 라우팅 설계 가이드

### TGW 라우트 테이블 설계 원칙

```
1. 환경별 격리 (prod/staging/dev)
   - 각 환경에 독립 라우트 테이블
   - 전파 설정으로 허용된 통신만 개방

2. 기능별 분리 (egress/shared/spoke)
   - egress: 인터넷 출구 VPC
   - shared: 공유 서비스 (DNS, NTP, 모니터링 등)
   - spoke: 애플리케이션 VPC

3. 블랙홀 우선순위
   - 정적 블랙홀 경로 > 전파 경로
   - 명시적 차단이 필요한 경우 반드시 블랙홀 추가
```

### TGW 서브넷 설계

TGW 어태치먼트용 전용 서브넷 사용 권장:

```
각 AZ당 /28 서브넷 1개 (16개 IP, TGW는 1개 사용)
예: 10.x.101.0/28, 10.x.102.0/28, 10.x.103.0/28
```

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | >= 5.0.0 |

## 참고 사항

- `tgw_default_route_table_association/propagation = false` 설정 권장 (수동 관리)
- TGW 어태치먼트용 전용 서브넷(`/28`) 사용 권장
- 멀티 어카운트 환경에서는 RAM 공유 활성화 후 수락 어카운트에서 어태치먼트 생성
- VPN 연결 시 IKEv2 + BGP 조합 권장 (안정성, 고가용성)

# terraform-vpc

재사용 가능한 AWS VPC Terraform 모듈입니다.
원시 AWS 리소스로 구성하여 커뮤니티 모듈 없이 동작합니다.

## 아키텍처

```
                          ┌─────────────────────────────────────┐
                          │               VPC                   │
                          │                                     │
  ┌─────────────┐         │  ┌──────────┐    ┌──────────┐      │
  │   Internet  │◄────────┤  │ Public   │    │ Public   │      │
  │   Gateway   │         │  │ Subnet A │    │ Subnet C │      │
  └─────────────┘         │  └────┬─────┘    └────┬─────┘      │
                          │       │ NAT            │ NAT(prod)  │
                          │  ┌────▼─────┐    ┌────▼─────┐      │
                          │  │ Private  │    │ Private  │      │
                          │  │ Subnet A │    │ Subnet C │      │
                          │  └──────────┘    └──────────┘      │
                          └─────────────────────────────────────┘
```

**환경별 특이사항:**
- `dev/staging`: 단일 NAT Gateway (비용 절약)
- `prod`: AZ별 NAT Gateway (단일 장애점 제거), Flow Logs 활성화, VPC Endpoint 활성화

## 모듈 구조

```
terraform-vpc/
├── modules/
│   └── vpc/
│       ├── main.tf        # VPC, 서브넷, IGW, NAT, 라우트 테이블, Endpoint, Flow Logs
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (VPC ID, 서브넷 ID 등)
│
├── envs/
│   ├── dev/               # 10.10.0.0/16, 2 AZ, 단일 NAT
│   ├── staging/           # 10.20.0.0/16, 2 AZ, 단일 NAT, S3 Endpoint
│   └── prod/              # 10.30.0.0/16, 3 AZ, AZ별 NAT, Flow Logs, Endpoint
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `aws_region` | AWS 리전 | ❌ | `ap-northeast-2` |
| `vpc_cidr` | VPC CIDR 블록 | ✅ | - |
| `azs` | 가용 영역 목록 | ✅ | - |
| `public_subnet_cidrs` | 퍼블릭 서브넷 CIDR 목록 | ❌ | `[]` |
| `private_subnet_cidrs` | 프라이빗 서브넷 CIDR 목록 | ❌ | `[]` |
| `enable_nat_gateway` | NAT Gateway 생성 여부 | ❌ | `true` |
| `single_nat_gateway` | 단일 NAT 사용 여부 | ❌ | `true` |
| `enable_s3_endpoint` | S3 VPC Endpoint 생성 | ❌ | `false` |
| `enable_dynamodb_endpoint` | DynamoDB VPC Endpoint 생성 | ❌ | `false` |
| `enable_flow_logs` | VPC Flow Logs 활성화 | ❌ | `false` |
| `flow_logs_retention_days` | Flow Logs 보존 기간 (일) | ❌ | `30` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR 블록 |
| `public_subnet_ids` | 퍼블릭 서브넷 ID 목록 |
| `private_subnet_ids` | 프라이빗 서브넷 ID 목록 |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_ids` | NAT Gateway ID 목록 |
| `nat_gateway_public_ips` | NAT Gateway 퍼블릭 IP 목록 |
| `public_route_table_id` | 퍼블릭 라우트 테이블 ID |
| `private_route_table_ids` | 프라이빗 라우트 테이블 ID 목록 |

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

### 4. 출력값 확인

```bash
terraform output
# vpc_id, subnet_ids, nat_gateway_public_ips 등 확인
```

### 5. 모듈 단독 사용 예시

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = "my-app"
  environment  = "prod"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # prod: AZ별 NAT

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_flow_logs         = true

  common_tags = {
    Project     = "my-app"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# 다른 모듈에서 VPC 출력값 참조
module "ec2" {
  source = "../ec2"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
}
```

## 환경별 CIDR 설계 (권장)

| 환경 | VPC CIDR | 퍼블릭 서브넷 | 프라이빗 서브넷 |
|------|----------|--------------|---------------|
| dev | 10.10.0.0/16 | 10.10.101~102.0/24 | 10.10.1~2.0/24 |
| staging | 10.20.0.0/16 | 10.20.101~102.0/24 | 10.20.1~2.0/24 |
| prod | 10.30.0.0/16 | 10.30.101~103.0/24 | 10.30.1~3.0/24 |

> 환경 간 VPC Peering 또는 Transit Gateway 연결 시 CIDR이 겹치지 않도록 주의하세요.

## 원격 백엔드 설정 (팀 협업 시 권장)

```bash
# S3 버킷 생성
aws s3 mb s3://your-tfstate-bucket --region ap-northeast-2

# DynamoDB 테이블 생성 (상태 잠금용)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2
```

`envs/*/backend.tf`의 주석을 해제하고 `bucket`, `dynamodb_table` 값을 변경하세요.

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

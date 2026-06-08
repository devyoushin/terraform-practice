# Terraform RDS 모듈

AWS RDS(MySQL 8.0) 인스턴스를 환경별(dev / staging / prod)로 배포하는 Terraform 프로젝트입니다.
재사용 가능한 모듈 구조로 설계되어 환경별 차이를 변수로 제어합니다.

---

## 아키텍처 다이어그램

```
                         ┌─────────────────────────────────────────────┐
                         │                   VPC                        │
                         │                                               │
                         │  ┌──────────────┐   ┌──────────────────┐    │
                         │  │  App Subnet  │   │  Private Subnet  │    │
                         │  │              │   │                  │    │
                         │  │  [EC2/ECS]  ─┼───┼─► [RDS SG]      │    │
                         │  │              │   │       │           │    │
                         │  └──────────────┘   │  ┌───▼────────┐  │    │
                         │                     │  │  RDS       │  │    │
                         │                     │  │  Instance  │  │    │
                         │                     │  │  (MySQL)   │  │    │
                         │                     │  └────────────┘  │    │
                         │                     │       (Multi-AZ) │    │
                         │                     │  ┌────────────┐  │    │
                         │                     │  │  Standby   │  │    │
                         │                     │  │  (prod만)  │  │    │
                         │                     │  └────────────┘  │    │
                         │                     └──────────────────┘    │
                         └─────────────────────────────────────────────┘
                                        │
                              ┌─────────▼──────────┐
                              │  CloudWatch Logs    │
                              │  (error/general/    │
                              │   slowquery)        │
                              └────────────────────┘
```

---

## 모듈 구조

```
terraform-rds/
├── modules/rds/            # 재사용 가능한 RDS 모듈
│   ├── main.tf             # 리소스 정의 (서브넷 그룹, SG, 파라미터 그룹, RDS 인스턴스)
│   ├── variables.tf        # 입력 변수 정의
│   └── outputs.tf          # 출력값 정의
├── envs/                   # 환경별 배포 설정
│   ├── dev/                # 개발 환경
│   ├── staging/            # 스테이징 환경
│   └── prod/               # 프로덕션 환경
├── README.md
├── .gitignore
├── terraform.tfvars.example
├── Makefile
└── .pre-commit-config.yaml
```

각 환경 디렉토리(`envs/<env>/`) 구성:
```
├── main.tf             # provider, locals, module 호출
├── variables.tf        # 변수 선언
├── terraform.tfvars    # 변수값 (Git 제외 대상)
├── backend.tf          # S3 원격 백엔드 설정 (주석 처리)
└── outputs.tf          # 출력값
```

---

## 환경별 비교표

| 항목 | dev | staging | prod |
|------|-----|---------|------|
| 인스턴스 클래스 | db.t3.micro | db.t3.small | db.t3.medium |
| Multi-AZ | false | false | **true** |
| 초기 스토리지 | 20 GiB | 50 GiB | 100 GiB |
| 최대 스토리지 | 50 GiB | 200 GiB | 500 GiB |
| 백업 보존 기간 | 7일 | 7일 | **30일** |
| 삭제 방지 | false | false | **true** |
| 최종 스냅샷 | 생략 (true) | 생성 (false) | **생성 (false)** |
| 변경 적용 | 즉시 (true) | 유지보수 창 | **유지보수 창** |
| Performance Insights | false | false | **true** |
| 스토리지 암호화 | true | true | true |

---

## 모듈 입력 변수표

| 변수명 | 타입 | 기본값 | 필수 | 설명 |
|--------|------|--------|------|------|
| `project_name` | string | - | O | 프로젝트 이름 |
| `environment` | string | - | O | 배포 환경 (dev/staging/prod) |
| `vpc_id` | string | - | O | VPC ID |
| `subnet_ids` | list(string) | - | O | 프라이빗 서브넷 ID 목록 |
| `allowed_cidr_blocks` | list(string) | - | O | RDS 접근 허용 CIDR |
| `db_engine` | string | `"mysql"` | - | DB 엔진 |
| `db_engine_version` | string | `"8.0"` | - | DB 엔진 버전 |
| `db_instance_class` | string | - | O | 인스턴스 클래스 |
| `db_name` | string | - | O | 데이터베이스 이름 |
| `db_username` | string | - | O | 마스터 사용자 이름 |
| `db_password` | string | - | O | 마스터 비밀번호 (sensitive) |
| `allocated_storage` | number | `20` | - | 초기 스토리지 (GiB) |
| `max_allocated_storage` | number | `100` | - | 최대 스토리지 (GiB) |
| `multi_az` | bool | `false` | - | Multi-AZ 활성화 |
| `backup_retention_period` | number | `7` | - | 백업 보존 기간 (일) |
| `backup_window` | string | `"03:00-04:00"` | - | 백업 시간 창 (UTC) |
| `maintenance_window` | string | `"Mon:04:00-Mon:05:00"` | - | 유지보수 시간 창 |
| `deletion_protection` | bool | `false` | - | 삭제 방지 활성화 |
| `skip_final_snapshot` | bool | `true` | - | 최종 스냅샷 생략 |
| `apply_immediately` | bool | `false` | - | 변경 즉시 적용 |
| `enable_performance_insights` | bool | `false` | - | Performance Insights 활성화 |
| `common_tags` | map(string) | `{}` | - | 공통 태그 |

---

## 모듈 출력값표

| 출력명 | 설명 |
|--------|------|
| `db_instance_id` | RDS 인스턴스 ID |
| `db_instance_arn` | RDS 인스턴스 ARN |
| `db_instance_endpoint` | 엔드포인트 (host:port) |
| `db_instance_address` | 호스트 주소 (host만) |
| `db_instance_port` | 포트 번호 |
| `db_name` | 데이터베이스 이름 |
| `db_username` | 마스터 사용자 이름 |
| `security_group_id` | RDS 시큐리티 그룹 ID |
| `db_subnet_group_name` | DB 서브넷 그룹 이름 |

---

## 사용 방법 (배포 순서)

### 1. 사전 준비

```bash
# Terraform 설치 (>= 1.5.0)
brew install terraform

# AWS CLI 설정
aws configure

# pre-commit 설치 (선택사항)
pip install pre-commit
pre-commit install
```

### 2. 변수값 파일 준비

```bash
# 예시 파일을 복사하여 실제 값으로 수정
cp terraform.tfvars.example envs/dev/terraform.tfvars
vi envs/dev/terraform.tfvars
```

### 3. Makefile로 배포 (권장)

```bash
# 개발 환경 배포
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# 스테이징 환경 배포
make init ENV=staging
make plan ENV=staging
make apply ENV=staging

# 프로덕션 환경 배포
make init ENV=prod
make plan ENV=prod
make apply ENV=prod

# 출력값 확인
make output ENV=dev

# 리소스 삭제 (주의)
make destroy ENV=dev
```

### 4. 직접 Terraform 명령어 사용

```bash
cd envs/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

### 5. S3 원격 백엔드 설정 (팀 협업 시)

```bash
# 1. S3 버킷 생성 (버저닝 활성화)
aws s3api create-bucket \
  --bucket your-tfstate-bucket \
  --region ap-northeast-2 \
  --create-bucket-configuration LocationConstraint=ap-northeast-2

# 2. S3 버저닝 활성화
aws s3api put-bucket-versioning \
  --bucket your-tfstate-bucket \
  --versioning-configuration Status=Enabled

# 3. DynamoDB 상태 잠금 테이블 생성
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2

# 4. backend.tf 주석 해제 후 재초기화
terraform init -reconfigure
```

---

## 보안 주의사항

### DB 비밀번호 관리

`db_password`를 `terraform.tfvars`에 평문으로 작성하지 마세요.
대신 아래 방법 중 하나를 사용하세요.

**방법 1: 환경변수로 주입 (권장)**

```bash
export TF_VAR_db_password="your-secure-password"
terraform apply
```

**방법 2: AWS Secrets Manager 사용 (프로덕션 권장)**

```bash
# Secrets Manager에 비밀번호 저장
aws secretsmanager create-secret \
  --name my-project/rds/db-password \
  --secret-string "your-secure-password"

# 배포 시 환경변수로 주입
export TF_VAR_db_password=$(aws secretsmanager get-secret-value \
  --secret-id my-project/rds/db-password \
  --query SecretString \
  --output text)
terraform apply
```

**방법 3: -var 플래그 사용**

```bash
terraform apply -var="db_password=your-secure-password"
```

### 추가 보안 권고사항

- `terraform.tfvars` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.
- S3 백엔드의 tfstate 파일에는 민감 정보가 포함될 수 있으므로 S3 버킷 암호화 및 접근 제어를 설정하세요.
- RDS는 퍼블릭 접근이 비활성화(`publicly_accessible = false`)되어 있습니다.
- 스토리지 암호화(`storage_encrypted = true`)는 항상 활성화됩니다.
- `allowed_cidr_blocks`는 최소 권한 원칙에 따라 필요한 CIDR만 허용하세요.
- prod 환경에서는 반드시 S3 원격 백엔드를 사용하세요.

---

## 요구사항

| 항목 | 최소 버전 |
|------|-----------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 |
| pre-commit (선택) | >= 3.0 |

### 필요한 AWS IAM 권한

배포 계정에 아래 서비스에 대한 권한이 필요합니다:
- `rds:*` - RDS 인스턴스 및 관련 리소스
- `ec2:*SecurityGroup*` - 시큐리티 그룹 관리
- `ec2:DescribeVpcs`, `ec2:DescribeSubnets` - 네트워크 조회
- `s3:*` - tfstate 백엔드 (원격 백엔드 사용 시)
- `dynamodb:*` - 상태 잠금 테이블 (원격 백엔드 사용 시)

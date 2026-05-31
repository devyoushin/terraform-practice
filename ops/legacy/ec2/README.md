# terraform-ec2

재사용 가능한 AWS EC2 Terraform 모듈입니다.
보안 그룹, EBS 볼륨, Elastic IP, IAM Instance Profile을 함께 관리합니다.

## 아키텍처

```
envs/
├── dev/        → t3.micro, 퍼블릭 서브넷, SSH 오픈
├── staging/    → t3.small, 프라이빗 서브넷, Bastion/VPN SSH
└── prod/       → t3.medium+, 프라이빗 서브넷, 세부 모니터링, IAM 프로파일
```

## 모듈 구조

```
terraform-ec2/
├── modules/
│   └── ec2/
│       ├── main.tf        # 보안 그룹, EC2 인스턴스, EIP 리소스
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (인스턴스 ID, IP 등)
│
└── envs/
    ├── dev/
    │   ├── main.tf            # Provider + module 호출
    │   ├── variables.tf       # 환경 변수 선언
    │   ├── terraform.tfvars   # 실제 값 입력 (Git 제외)
    │   ├── backend.tf         # S3 원격 상태 저장소
    │   └── outputs.tf         # 환경 출력값
    ├── staging/
    └── prod/
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 (리소스 prefix) | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `vpc_id` | 배포할 VPC ID | ✅ | - |
| `subnet_id` | 배포할 서브넷 ID | ✅ | - |
| `ami_id` | 사용할 AMI ID | ✅ | - |
| `instance_type` | EC2 인스턴스 타입 | ✅ | - |
| `key_pair_name` | SSH Key Pair 이름 | ✅ | - |
| `ingress_rules` | 보안 그룹 인바운드 규칙 | ❌ | `[]` |
| `associate_public_ip` | 퍼블릭 IP 자동 할당 | ❌ | `false` |
| `root_volume_size` | 루트 EBS 크기 (GB) | ❌ | `20` |
| `root_volume_iops` | 루트 볼륨 IOPS | ❌ | `3000` |
| `root_volume_throughput` | 루트 볼륨 처리량 (MiB/s) | ❌ | `125` |
| `extra_ebs_volumes` | 추가 EBS 볼륨 목록 | ❌ | `[]` |
| `create_eip` | Elastic IP 생성 여부 | ❌ | `false` |
| `iam_instance_profile` | IAM Instance Profile 이름 | ❌ | `null` |
| `enable_detailed_monitoring` | 세부 모니터링 활성화 | ❌ | `false` |
| `user_data` | 인스턴스 시작 스크립트 | ❌ | `null` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `instance_id` | EC2 인스턴스 ID |
| `instance_arn` | EC2 인스턴스 ARN |
| `private_ip` | 프라이빗 IP 주소 |
| `public_ip` | 퍼블릭 IP 주소 |
| `elastic_ip` | Elastic IP 주소 (생성 시) |
| `security_group_id` | 보안 그룹 ID |
| `security_group_arn` | 보안 그룹 ARN |

## 사용 방법

### 1. 변수 파일 준비

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집하여 실제 값 입력
```

### 2. 초기화 및 배포

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. 모듈 단독 사용 예시

```hcl
module "ec2" {
  source = "../../modules/ec2"

  project_name = "my-app"
  environment  = "dev"

  vpc_id    = "vpc-xxxxxxxx"
  subnet_id = "subnet-xxxxxxxx"

  ami_id        = "ami-056a29f2eddc40520"
  instance_type = "t3.micro"
  key_pair_name = "my-keypair"

  ingress_rules = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["1.2.3.4/32"]
    }
  ]

  root_volume_size = 20
  common_tags = {
    Project     = "my-app"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## 환경별 설정 차이

| 항목 | dev | staging | prod |
|------|-----|---------|------|
| 인스턴스 타입 | t3.micro | t3.small | t3.medium+ |
| 퍼블릭 IP | ✅ | ❌ | ❌ |
| SSH 허용 대역 | 0.0.0.0/0 | Bastion/VPN | Bastion/VPN |
| 세부 모니터링 | ❌ | ❌ | ✅ |
| IAM 프로파일 | 선택 | 선택 | 권장 |
| EIP | ❌ | 선택 | 선택 |

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

`envs/*/backend.tf`의 `bucket`, `dynamodb_table` 값을 실제 이름으로 변경하세요.

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |

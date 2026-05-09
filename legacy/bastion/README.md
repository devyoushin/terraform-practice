# terraform-bastion

재사용 가능한 AWS Bastion Host Terraform 모듈입니다.
SSH Bastion과 SSM Session Manager 두 가지 접속 방식을 지원합니다.

## 아키텍처

```
[SSM 전용 모드 - 권장]               [SSH Bastion 모드]
사용자                               사용자
  │                                    │
  ▼                                    ▼ (SSH 22 포트)
AWS Systems Manager                  Bastion EC2 (퍼블릭 IP/EIP)
  │                                    │
  ▼                                    ▼
Bastion EC2 (프라이빗 서브넷)         프라이빗 리소스 (RDS, Redis 등)
  │
  ▼
프라이빗 리소스 (RDS, Redis 등)
```

**SSM Session Manager 방식이 권장되는 이유:**
- 22 포트를 열지 않아도 됨 (보안 강화)
- SSH Key 관리 불필요
- 접속 세션 자동 CloudTrail 기록

## 모듈 구조

```
terraform-bastion/
├── modules/
│   └── bastion/
│       ├── main.tf        # EC2, IAM Role, 보안 그룹, EIP
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (인스턴스 ID, SSM 접속 명령어 등)
│
├── envs/
│   ├── dev/               # 개발 환경
│   └── prod/              # 운영 환경
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `vpc_id` | 배포할 VPC ID | ✅ | - |
| `subnet_id` | 배포할 서브넷 ID | ✅ | - |
| `ami_id` | AMI ID (Amazon Linux 2023 권장) | ✅ | - |
| `instance_type` | EC2 인스턴스 타입 | ❌ | `"t3.micro"` |
| `enable_ssh` | SSH Bastion 모드 활성화 | ❌ | `false` |
| `key_pair_name` | SSH Key Pair 이름 | ❌ | `null` |
| `allowed_ssh_cidr` | SSH 허용 IP 목록 (CIDR) | ❌ | `[]` |
| `create_eip` | Elastic IP 생성 여부 | ❌ | `false` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `instance_id` | Bastion EC2 인스턴스 ID |
| `private_ip` | 프라이빗 IP |
| `public_ip` | 퍼블릭 IP (SSH 모드 시) |
| `security_group_id` | 보안 그룹 ID |
| `iam_role_arn` | IAM Role ARN |
| `ssm_connect_command` | SSM 접속 명령어 |

## 사용 방법

### 1. 환경 디렉토리로 이동

```bash
cd envs/dev   # 또는 envs/prod
```

### 2. 변수 파일 복사 및 편집

```bash
cp ../../terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집하여 실제 값 입력
```

### 3. AMI ID 조회 (최신 Amazon Linux 2023)

```bash
aws ssm get-parameter \
  --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" \
  --region ap-northeast-2 \
  --query "Parameter.Value" --output text
```

### 4. 초기화 및 배포

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 5. SSM으로 접속

```bash
# terraform output으로 명령어 확인
terraform output ssm_connect_command

# 또는 직접 실행
aws ssm start-session --target <instance-id> --region ap-northeast-2
```

### 6. 포트 포워딩 (예: RDS 접근)

```bash
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["rds-endpoint.xxx.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5432"]}' \
  --region ap-northeast-2
```

## 원격 백엔드 설정 (팀 협업 시 권장)

`envs/*/backend.tf`의 주석을 해제하고 `bucket`, `dynamodb_table` 값을 변경하세요.

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 (SSM 접속 시) |
| Session Manager Plugin | 최신 버전 (SSM 접속 시) |

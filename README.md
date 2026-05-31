# Terraform AWS 인프라 실습 저장소

프로덕션 수준의 Terraform 모듈 모음으로, VPC부터 EKS, RDS, CloudFront까지 AWS 전체 스택을 다룹니다.
각 모듈은 **dev / prod 두 가지 환경**에 걸쳐 실무 운영 패턴을 포함합니다.

---

## 어디서 시작할까

- 문서 지도: `docs/README.md`
- 운영 실행 가이드: `ops/README.md`
- AI 작업 지침: `CLAUDE.md`
- Codex 작업 지침: `AGENTS.md` → `CLAUDE.md`
- 최초 1회 state 인프라: `ops/bootstrap/`
- 권장 실행 경로: `ops/dev/`, `ops/prod/`의 Terragrunt 호출부
- 모듈 소스: `ops/legacy/{module}/`

---

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                          엣지 레이어                             │
│          Route53 → CloudFront (WAF) → ALB (WAF)                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                        컴퓨트 레이어                             │
│               EC2 / EKS (Karpenter) / Bastion                   │
└──────┬────────────────────────────────┬──────────────────────────┘
       │                                │
┌──────▼──────────┐          ┌──────────▼──────────┐
│   데이터 레이어  │          │    메시징 레이어     │
│  RDS / DynamoDB │          │    SQS / SNS         │
│  ElastiCache    │          └─────────────────────┘
│  S3 / Backup    │
└─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    보안 및 자격 증명 레이어                      │
│         IAM / KMS / Secrets Manager / WAF / GuardDuty           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        네트워크 기반                             │
│              VPC / TGW (멀티 계정) / Route53                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    옵저버빌리티 및 CI/CD                         │
│          CloudWatch / ECR / CodePipeline / CodeBuild             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 디렉토리 구조

```
terraform-practice/
├── README.md                 # 프로젝트 입구
├── CLAUDE.md                 # Claude/Codex 공통 작업 지침 원본
├── AGENTS.md -> CLAUDE.md    # Codex용 지침 링크
├── docs/                     # 문서 규칙, 템플릿, AI 에이전트 지침
│   ├── README.md
│   ├── agents/
│   ├── checklists/
│   ├── runbooks/
│   ├── rules/
│   ├── outputs.md
│   └── templates/
└── ops/                      # 실제 Terraform/Terragrunt 실행 자산
    ├── terragrunt.hcl        # ops 루트: remote_state + provider 자동 생성
    ├── _envs/                # 환경별 변수 참조 문서 (dev.hcl, prod.hcl)
    ├── bootstrap/            # Remote State 인프라 (최초 1회 실행)
    ├── dev/                  # DEV 환경 (VPC CIDR 10.10.0.0/16)
    │   ├── env.hcl           # environment = "dev"
    │   └── {모듈}/terragrunt.hcl
    ├── prod/                 # PROD 환경 (VPC CIDR 10.0.0.0/16, 3 AZ)
    │   ├── env.hcl           # environment = "prod"
    │   └── {모듈}/terragrunt.hcl
    ├── scripts/              # 반복 점검용 보조 스크립트
    ├── outputs/              # plan, graph, 점검 결과 보관 위치
    └── legacy/               # 레거시 패턴 (Terragrunt source로 참조)
        └── {모듈}/
            ├── modules/{모듈}/
            ├── envs/{dev,prod}/
            └── Makefile
```

## 구조 기준

이 저장소는 일반적인 문서형 practice 저장소보다 실행 코드가 많습니다. 따라서 `prometheus-practice`처럼 문서 보조 자료는 `docs/`에 모으고, 실제 Terraform 실행 자산은 `ops/` 아래에 둡니다.

| 경로 | 역할 |
|------|------|
| `docs/` | AI 에이전트 지침, 작성 규칙, 체크리스트, 런북, 템플릿 |
| `docs/checklists/` | apply 전 점검과 모듈 리뷰 기준 |
| `docs/runbooks/` | drift detection, state import 운영 절차 |
| `docs/outputs.md` | plan, graph, 점검 결과 보관 규칙 |
| `ops/bootstrap/` | Terraform backend용 S3/DynamoDB 최초 생성 |
| `ops/dev/`, `ops/prod/` | 환경별 Terragrunt live configuration |
| `ops/legacy/` | 재사용 Terraform 모듈과 레거시 직접 실행 예제 |
| `ops/_envs/` | 환경별 공통 변수 참조 |
| `ops/scripts/` | 반복 plan, state 요약 등 보조 스크립트 |
| `ops/outputs/` | plan, graph, 점검 결과 보관 위치 |

`CLAUDE.md`와 `AGENTS.md`는 별도 파일로 관리하지 않습니다. `AGENTS.md`는 `CLAUDE.md`를 가리키는 심볼릭 링크이므로, 작업 지침은 `CLAUDE.md`만 수정하면 됩니다.

---

## 빠른 시작 (Terragrunt — 권장)

### 1. 사전 설치

```bash
brew install terraform terragrunt
terraform version   # >= 1.6.0
terragrunt --version
```

### 2. Remote State 인프라 생성 (최초 1회)

```bash
cd ops/bootstrap
terraform init
terraform apply
# → S3 버킷(terraform-practice-tfstate) + DynamoDB 테이블 생성
```

### 3. 단일 모듈 실행

```bash
cd ops/dev/vpc
terragrunt init    # S3 백엔드 자동 설정, provider.tf 자동 생성
terragrunt plan
terragrunt apply
terragrunt output  # vpc_id, private_subnet_ids 확인
```

### 4. 환경 전체 실행 (의존성 자동 처리)

```bash
# DEV 전체 plan (VPC → KMS → RDS 순서 자동 계산)
terragrunt run-all plan --terragrunt-working-dir ops/dev/

# DEV 전체 apply
terragrunt run-all apply --terragrunt-working-dir ops/dev/

# 의존성 그래프 시각화
terragrunt graph-dependencies --terragrunt-working-dir ops/dev/ | dot -Tsvg > graph.svg
```

---

## 모듈 목록

| 모듈 | 설명 |
|------|------|
| [vpc](./ops/legacy/vpc/) | VPC, 서브넷, NAT Gateway, VPC Endpoints, Flow Logs |
| [ec2](./ops/legacy/ec2/) | EC2 인스턴스, EBS, Security Groups, IAM 프로파일 |
| [alb](./ops/legacy/alb/) | Application Load Balancer, HTTPS/ACM, 액세스 로그 |
| [rds](./ops/legacy/rds/) | RDS MySQL 8.0, Multi-AZ, 백업, Performance Insights |
| [eks](./ops/legacy/eks/) | EKS 클러스터, 관리형 노드 그룹, Karpenter, IRSA |
| [ecr](./ops/legacy/ecr/) | ECR, 이미지 스캔, 수명 주기 정책 |
| [elasticache](./ops/legacy/elasticache/) | ElastiCache Redis, Multi-AZ, 암호화, 스냅샷 |
| [dynamodb](./ops/legacy/dynamodb/) | DynamoDB, OnDemand/Provisioned, GSI, PITR |
| [s3](./ops/legacy/s3/) | S3 버킷, 버전 관리, 수명 주기, 암호화 |
| [cloudfront](./ops/legacy/cloudfront/) | CloudFront CDN, OAC, WAF 연동, 커스텀 도메인 |
| [waf](./ops/legacy/waf/) | WAF v2, IP 차단, 레이트 리밋, 관리형 규칙 |
| [iam](./ops/legacy/iam/) | IAM 역할: EC2, GitHub OIDC (CI/CD), EKS IRSA |
| [kms](./ops/legacy/kms/) | KMS 키, 자동 교체, 멀티 리전 |
| [secrets-manager](./ops/legacy/secrets-manager/) | Secrets Manager, KMS 암호화, 자동 교체 |
| [cloudwatch](./ops/legacy/cloudwatch/) | CloudWatch Logs, 알람, 대시보드, SNS |
| [bastion](./ops/legacy/bastion/) | Bastion 호스트, SSM Session Manager, SSH |
| [route53](./ops/legacy/route53/) | 호스팅 존, DNS 레코드, 헬스 체크, 페일오버 |
| [sqs-sns](./ops/legacy/sqs-sns/) | SQS 큐, SNS 토픽, DLQ, 구독 |
| [backup](./ops/legacy/backup/) | AWS Backup, 볼트, 계획, 보존 기간 관리 |
| [guardduty](./ops/legacy/guardduty/) | GuardDuty, 위협 감지, SNS 알림, 심각도 필터 |
| [codepipeline](./ops/legacy/codepipeline/) | CodePipeline, CodeBuild, ECS 배포 (Rolling/Blue-Green) |
| [tgw](./ops/legacy/tgw/) | Transit Gateway, 허브-앤-스포크, VPN, RAM 공유 |

---

## 모듈 간 배포 순서

Terragrunt `dependency` 블록으로 자동 처리됩니다. 수동 적용 시 아래 순서를 따르세요.

```
1. vpc              ← 모든 모듈의 기반
2. iam              ← 서비스 역할 및 OIDC Provider
3. kms              ← 암호화 키 (RDS/S3/SQS 사용 전 필요)
4. route53          ← ACM 인증서 발급 전 호스팅 존 필요
5. s3               ← CloudFront Origin, 로그 버킷
6. ecr              ← EKS 배포 전 이미지 저장소
7. eks              ← vpc, iam, ecr 이후
8. rds              ← vpc, kms, secrets-manager 이후
9. elasticache      ← vpc 이후
10. alb             ← vpc, route53, ACM 이후
11. cloudfront      ← alb, s3, waf, route53 이후
12. backup          ← 보호 대상 리소스 생성 이후
13. guardduty       ← 독립적으로 배포 가능
14. codepipeline    ← ecr, ecs 클러스터 이후
```

---

## CIDR 설계

| 환경 | VPC CIDR | AZ |
|------|----------|-----|
| prod | `10.0.0.0/16` | 3 AZ |
| dev | `10.10.0.0/16` | 2 AZ |
| TGW Hub | `10.100.0.0/16` | 멀티 계정 연결 |

서브넷 규칙: `10.{env}.0~9.x/24` → 퍼블릭 / `10.{env}.10~19.x/24` → 프라이빗

---

## 환경별 비교

| 항목 | dev | prod |
|------|-----|------|
| VPC CIDR | `10.10.0.0/16` | `10.0.0.0/16` |
| 가용성 | 단일 AZ (2 AZ) | Multi-AZ (3 AZ) |
| KMS 암호화 | 선택적 | 필수 |
| 백업/보존 | 최단 | 최장 |
| 삭제 보호 | 비활성 | 활성 |
| 모니터링 | 기본 | 전체 + 알람 |
| `force_destroy` | `true` | `false` |
| `prevent_destroy` | 없음 | 필수 |

---

## 레거시 패턴 (Makefile)

레거시 패턴은 각 모듈의 `ops/legacy/{모듈}/` 디렉토리에서 직접 실행합니다.

```bash
cd ops/legacy/vpc/envs/dev
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# Makefile 단축 명령
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

---

## 실무 운영 가이드

### prod 적용 전 필수 절차

```bash
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt
grep "will be destroyed" tfplan.txt  # 삭제 예정 리소스 확인
terraform apply tfplan.binary        # 검토한 플랜 그대로 적용
```

### 시크릿 관리

`*.tfvars`는 Git에 커밋하지 않습니다 (`.gitignore` 적용, `*.tfvars.example`만 허용).

```bash
# CI/CD — SSM Parameter Store 활용
aws ssm put-parameter --name "/prod/rds/password" --value "..." --type "SecureString"
```

```hcl
data "aws_ssm_parameter" "db_password" {
  name            = "/prod/rds/password"
  with_decryption = true
}
```

### 상태 파일 격리

```
✅ 올바른 방법: 모듈별 격리
  prod/vpc/terraform.tfstate
  prod/rds/terraform.tfstate
  prod/eks/terraform.tfstate

❌ 잘못된 방법: 단일 상태 파일
  terraform/terraform.tfstate
```

### 상태 작업

```bash
terraform import aws_db_instance.main <identifier>   # 기존 리소스 가져오기
terraform state mv aws_s3_bucket.old aws_s3_bucket.new  # 이름 변경
terraform state rm aws_instance.legacy               # 상태에서 제거 (삭제 없이)
terraform plan -refresh-only                         # 드리프트 감지
```

---

## 보안 체크리스트

- [ ] `terraform.tfvars`가 Git에 커밋되지 않음
- [ ] S3 상태 버킷에 버전 관리 및 암호화 활성화, 퍼블릭 액세스 차단
- [ ] DynamoDB 잠금 테이블이 `backend.tf`에서 참조됨
- [ ] IAM 역할이 최소 권한 원칙 준수
- [ ] 모든 prod 데이터베이스에 `deletion_protection = true`
- [ ] prod stateful 리소스에 `prevent_destroy = true`
- [ ] 적용 전 플랜 출력 검토 완료

---

## pre-commit

각 모듈에는 `.pre-commit-config.yaml`이 포함됩니다.

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

검사 항목: `terraform fmt` / `terraform validate` / `tflint` / `checkov`

---

## 요구사항

| 항목 | 버전 |
|------|------|
| Terraform | >= 1.6.0 |
| AWS Provider | ~> 5.0 |
| Terragrunt | 최신 안정 버전 |
| AWS CLI | >= 2.0 |
| kubectl | 최신 안정 버전 (EKS 사용 시) |
| helm | >= 3.0 (EKS 사용 시) |

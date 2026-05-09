# Terraform AWS Backup 모듈

재사용 가능한 AWS Backup 관리 Terraform 모듈입니다. 환경별(dev/staging/prod) 분리 구성을 통해 안전하고 일관된 백업 인프라를 제공합니다.

---

## 주요 기능

| 기능 | 설명 |
|---|---|
| 백업 볼트 | KMS 암호화 지원, 논리적 백업 데이터 컨테이너 |
| 백업 플랜 | cron 스케줄 기반 자동 백업, 보존 기간 설정 |
| 콜드 스토리지 전환 | 오래된 백업을 자동으로 저렴한 스토리지로 이동 (prod 권장) |
| ARN 기반 대상 선택 | 특정 리소스 ARN을 명시적으로 지정하여 백업 |
| 태그 기반 대상 선택 | 특정 태그를 가진 모든 리소스를 자동으로 백업 대상에 포함 |
| IAM 역할 자동 생성 | AWS Backup 서비스 역할 및 복원 권한 정책 자동 연결 |

---

## 지원 리소스

AWS Backup이 지원하는 모든 리소스 타입을 백업할 수 있습니다.

| 서비스 | 백업 가능 리소스 |
|---|---|
| RDS | DB 인스턴스, Aurora 클러스터 |
| DynamoDB | 테이블 (Point-In-Time Recovery와 별개) |
| EFS | 파일 시스템 |
| EBS | EC2 연결 볼륨 |
| S3 | 버킷 (고급 기능 활성화 필요) |
| DocumentDB | 클러스터 |

---

## 환경별 비교

| 항목 | dev | staging | prod |
|---|---|---|---|
| 백업 보존 기간 | 7일 | 14일 | 30일 이상 |
| 콜드 스토리지 전환 | 비활성화 | 비활성화 | 선택적 활성화 |
| KMS 암호화 | AWS 관리형 | AWS 관리형 | 고객 관리형 KMS |
| 태그 기반 선택 | 비활성화 | 선택적 | 활성화 권장 |
| `prevent_destroy` | 없음 | 없음 | 볼트에 적용 권장 |

---

## 디렉토리 구조

```
backup/
├── modules/backup/      # 재사용 가능한 AWS Backup 모듈
│   ├── main.tf          # 볼트, 플랜, 대상 선택, IAM 역할 정의
│   ├── variables.tf     # 모듈 입력 변수
│   └── outputs.tf       # 모듈 출력값
├── envs/
│   ├── dev/             # 개발 환경 (7일 보존, 비용 최소화)
│   │   └── main.tf
│   ├── staging/         # 스테이징 환경 (14일 보존)
│   └── prod/            # 운영 환경 (30일+, KMS 암호화, 태그 선택)
├── Makefile             # 환경별 작업 자동화
├── .pre-commit-config.yaml
└── README.md
```

---

## 모듈 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `project_name` | `string` | 필수 | 프로젝트 이름 |
| `environment` | `string` | 필수 | 환경: `dev`, `staging`, `prod` |
| `vault_name` | `string` | `"Default"` | 볼트 이름 접미사 |
| `kms_key_arn` | `string` | `null` | KMS 키 ARN (null이면 AWS 관리형 키) |
| `backup_schedule` | `string` | `"cron(0 3 * * ? *)"` | 백업 스케줄 (UTC 기준 cron) |
| `delete_after_days` | `number` | `30` | 백업 보존 기간 (일) |
| `cold_storage_after_days` | `number` | `null` | 콜드 스토리지 전환 일수 (null이면 비활성화) |
| `resource_arns` | `list(string)` | `[]` | 백업 대상 리소스 ARN 목록 |
| `selection_tag` | `object` | `null` | 태그 기반 리소스 선택 설정 |
| `common_tags` | `map(string)` | `{}` | 공통 태그 맵 |

### `selection_tag` 객체 구조

```hcl
selection_tag = {
  type  = "STRINGEQUALS"   # STRINGEQUALS / STRINGLIKE / STRINGNOTEQUALS 등
  key   = "Backup"         # 태그 키
  value = "true"           # 태그 값
}
```

---

## 모듈 출력값

| 출력값 | 설명 |
|---|---|
| `backup_vault_arn` | 백업 볼트 ARN |
| `backup_vault_name` | 백업 볼트 이름 |
| `backup_plan_id` | 백업 플랜 ID |
| `backup_plan_arn` | 백업 플랜 ARN |
| `backup_iam_role_arn` | AWS Backup 서비스 IAM 역할 ARN |

---

## 사전 준비

### 1. 사전 요구사항 확인

```bash
# Terraform 버전 확인 (1.5.0 이상 필요)
terraform version

# AWS 자격증명 설정
aws configure

# 필요 IAM 권한
# - backup:* (백업 볼트, 플랜, 선택 대상 관리)
# - iam:CreateRole, iam:AttachRolePolicy (서비스 역할 생성)
# - kms:CreateGrant (KMS 암호화 사용 시)
```

### 2. 백업 대상 리소스 ARN 확인

```bash
# RDS 인스턴스 ARN 확인
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceArn]' \
  --output table

# DynamoDB 테이블 ARN 확인
aws dynamodb list-tables --query 'TableNames[]' --output text | \
  xargs -I{} aws dynamodb describe-table --table-name {} \
  --query 'Table.TableArn' --output text

# EFS 파일 시스템 ARN 확인
aws efs describe-file-systems \
  --query 'FileSystems[*].[FileSystemId,FileSystemArn]' \
  --output table
```

---

## 배포 방법

### Makefile 이용 (권장)

```bash
# 개발 환경 배포
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# 운영 환경 배포 (신중히 진행)
make init ENV=prod
make plan ENV=prod
make apply ENV=prod

# 출력값 확인 (볼트 ARN 등)
make output ENV=prod
```

### 직접 Terraform 명령

```bash
cd envs/dev

# 변수 파일 준비
cp ../../terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# 초기화 및 배포
terraform init
terraform plan
terraform apply
```

---

## 사용 예시

### dev 환경: 특정 RDS 인스턴스 백업

```hcl
module "backup" {
  source = "../../modules/backup"

  project_name = "my-project"
  environment  = "dev"

  backup_schedule   = "cron(0 3 * * ? *)"   # 매일 UTC 새벽 3시
  delete_after_days = 7

  resource_arns = [
    "arn:aws:rds:ap-northeast-2:123456789012:db:dev-mysql"
  ]
}
```

### prod 환경: 태그 기반 전체 선택 + KMS 암호화

```hcl
module "backup" {
  source = "../../modules/backup"

  project_name = "my-project"
  environment  = "prod"

  # KMS 고객 관리형 키 사용 (보안 강화)
  kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/..."

  # 매일 UTC 새벽 3시 백업
  backup_schedule = "cron(0 3 * * ? *)"

  # 30일 보존, 90일 후 콜드 스토리지 전환 (비용 최적화)
  delete_after_days       = 90
  cold_storage_after_days = 30

  # Backup=true 태그를 가진 모든 리소스 자동 백업
  selection_tag = {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
```

> 백업 대상 리소스에 `Backup = "true"` 태그를 추가하면 자동으로 백업에 포함됩니다.

---

## 백업 복원

### 복원 방법 선택 기준

| 시나리오 | 권장 방법 | 이유 |
|---|---|---|
| AWS Backup vault 복구 포인트 복원 | **CLI / SDK** | Terraform에 `aws_backup_restore_job` 리소스 없음 |
| RDS 스냅샷 → 새 인스턴스 (Terraform 관리) | **Terraform** | `snapshot_identifier`로 복원 후 계속 관리 |
| EBS 스냅샷 → 새 볼륨 (Terraform 관리) | **Terraform** | `snapshot_id`로 복원 후 계속 관리 |
| DynamoDB PITR (Terraform 관리) | **Terraform** | `restore_to_point_in_time` 블록 사용 |
| 긴급 일회성 복구 | **CLI** | 가장 빠른 대응 가능 |
| 자동화 복구 파이프라인 | **SDK (boto3)** | 조건 분기 및 상태 관리 용이 |

---

### AWS 콘솔에서 복원

1. AWS 콘솔 → AWS Backup → 복구 포인트
2. 복원할 복구 포인트 선택
3. "복원" 클릭 → 복원 설정 구성 → 복원 시작

---

### AWS CLI로 복원 (AWS Backup 복구 포인트)

```bash
# 복구 포인트 목록 확인
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name my-project-prod-Default \
  --region ap-northeast-2

# RDS 인스턴스 복원
aws backup start-restore-job \
  --recovery-point-arn "arn:aws:backup:ap-northeast-2:123456789012:recovery-point:..." \
  --metadata '{
    "DBInstanceIdentifier": "my-project-prod-rds-restored",
    "DBInstanceClass":      "db.t3.medium",
    "Engine":               "mysql",
    "MultiAZ":              "false"
  }' \
  --iam-role-arn "arn:aws:iam::123456789012:role/my-project-prod-backup-role" \
  --resource-type RDS \
  --region ap-northeast-2

# EBS 볼륨 복원
aws backup start-restore-job \
  --recovery-point-arn "arn:aws:backup:ap-northeast-2:123456789012:recovery-point:..." \
  --metadata '{
    "volumeId":           "vol-xxxxxxxxxxxxxxxxx",
    "availabilityZone":   "ap-northeast-2a",
    "encrypted":          "true"
  }' \
  --iam-role-arn "arn:aws:iam::123456789012:role/my-project-prod-backup-role" \
  --resource-type "EBS" \
  --region ap-northeast-2

# 복원 작업 상태 확인
aws backup describe-restore-job \
  --restore-job-id <JOB_ID> \
  --region ap-northeast-2
```

---

### Terraform으로 복원 (스냅샷 기반)

> Terraform으로 복원하면 복원된 리소스가 Terraform state에 포함되어 이후 변경도 코드로 관리할 수 있습니다.

#### RDS 스냅샷 복원

```hcl
# envs/prod/main.tf — 스냅샷에서 새 RDS 인스턴스 생성
resource "aws_db_instance" "restored" {
  identifier     = "my-project-prod-rds-restored"
  instance_class = "db.t3.medium"

  # 복원할 스냅샷 ARN 또는 ID
  snapshot_identifier = "arn:aws:rds:ap-northeast-2:123456789012:snapshot:rds:my-db-2026-04-15-03-00"

  # 스냅샷에서 복원 시 engine/username은 자동 상속
  # password는 apply 후 반드시 수동 변경 또는 Secrets Manager 연동 필요

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = false
  deletion_protection    = true

  tags = merge(local.common_tags, {
    Name        = "my-project-prod-rds-restored"
    RestoredFrom = "snapshot"
  })
}
```

#### DynamoDB PITR 복원

```hcl
# 특정 시점으로 테이블 복원
resource "aws_dynamodb_table" "restored" {
  name         = "my-table-restored"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  restore_to_point_in_time {
    source_table_name          = "my-table-prod"
    restore_date_time          = "2026-04-14T03:00:00Z"  # UTC 기준
    use_latest_restorable_time = false                    # true로 설정 시 restore_date_time 무시
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.common_tags
}
```

#### EBS 스냅샷 복원

```hcl
# 스냅샷에서 새 EBS 볼륨 생성
resource "aws_ebs_volume" "restored" {
  availability_zone = "ap-northeast-2a"
  snapshot_id       = "snap-xxxxxxxxxxxxxxxxx"
  type              = "gp3"
  encrypted         = true
  kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "my-project-prod-ebs-restored"
  })
}
```

---

### 복원 후 Terraform State 관리

CLI로 복원한 리소스를 이후 Terraform으로 관리하려면 `import`가 필요합니다.

```bash
# 1. Terraform 코드에 리소스 블록 추가 후 import 실행

# RDS import
terraform import aws_db_instance.restored my-project-prod-rds-restored

# EBS 볼륨 import
terraform import aws_ebs_volume.restored vol-xxxxxxxxxxxxxxxxx

# DynamoDB import
terraform import aws_dynamodb_table.restored my-table-restored

# 2. import 후 plan으로 drift 확인 (변경사항 없어야 정상)
terraform plan
```

> **주의:** `terraform import` 후 반드시 `terraform plan`을 실행하여 실제 리소스 설정과 코드가 일치하는지 확인하세요. diff가 발생하면 코드를 실제 값에 맞게 수정합니다.

---

### prod 긴급 복구 절차 (RTO 최소화)

```bash
# Step 1. 최신 복구 포인트 확인
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name my-project-prod-Default \
  --query 'RecoveryPoints | sort_by(@, &CreationDate) | [-1]' \
  --output json

# Step 2. 복원 작업 시작 (CLI — 가장 빠름)
RESTORE_JOB=$(aws backup start-restore-job \
  --recovery-point-arn "<RECOVERY_POINT_ARN>" \
  --metadata '{"DBInstanceIdentifier":"my-project-prod-rds-emergency"}' \
  --iam-role-arn "<BACKUP_ROLE_ARN>" \
  --resource-type RDS \
  --query 'RestoreJobId' --output text)

# Step 3. 복원 완료까지 상태 폴링
watch -n 30 "aws backup describe-restore-job --restore-job-id $RESTORE_JOB \
  --query '[Status, PercentDone]' --output text"

# Step 4. 복원 완료 후 엔드포인트 확인
aws rds describe-db-instances \
  --db-instance-identifier my-project-prod-rds-emergency \
  --query 'DBInstances[0].Endpoint'

# Step 5. (선택) 안정화 후 Terraform으로 import하여 코드 관리 전환
terraform import aws_db_instance.main my-project-prod-rds-emergency
```

---

## 백업 스케줄 참고 (cron, UTC 기준)

| cron 표현식 | 실행 시각 | 설명 |
|---|---|---|
| `cron(0 3 * * ? *)` | 매일 03:00 UTC (KST 12:00) | 기본값 |
| `cron(0 18 * * ? *)` | 매일 18:00 UTC (KST 03:00 익일) | 야간 백업 |
| `cron(0 3 ? * 1 *)` | 매주 월요일 03:00 UTC | 주간 백업 |
| `cron(0 3 1 * ? *)` | 매월 1일 03:00 UTC | 월간 백업 |

> AWS Backup cron은 6자리 형식을 사용합니다: `분 시 일 월 요일 연도`

---

## 트러블슈팅

### 백업 작업 실패 — IAM 권한 부족

```bash
# 백업 작업 상태 확인
aws backup list-backup-jobs \
  --by-backup-vault-name my-project-dev-Default \
  --by-state FAILED

# 상세 오류 확인
aws backup describe-backup-job --backup-job-id <JOB_ID>
```

일반적인 원인: 백업 대상 리소스에 대한 IAM 권한 부족.
`AWSBackupServiceRolePolicyForBackup` 관리형 정책이 역할에 연결되어 있는지 확인하세요.

### DynamoDB 백업 활성화

DynamoDB 백업을 위해 먼저 Advanced Backup 기능을 활성화해야 합니다.

```bash
aws dynamodb update-continuous-backups \
  --table-name my-table \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### 콜드 스토리지 전환 오류

`cold_storage_after_days`는 반드시 `delete_after_days`보다 작아야 합니다.

```
cold_storage_after_days(30) < delete_after_days(90)  ← 올바름
cold_storage_after_days(90) < delete_after_days(30)  ← 오류
```

---

## 요구사항

| 항목 | 버전 |
|---|---|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | >= 2.0 |

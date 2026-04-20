# Terraform 코드 표준 관행

## 디렉토리 구조

모든 모듈은 `modules/` + `envs/` 분리 패턴을 따른다.

```
<module>/
├── modules/<module>/    # 재사용 가능한 리소스 정의
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── envs/
│   ├── dev/             # force_destroy=true, 비용 최소
│   └── prod/            # prevent_destroy, 완전한 보호
├── Makefile
├── .pre-commit-config.yaml
├── terraform.tfvars.example
└── README.md
```

## 필수 변수 패턴

모든 모듈의 variables.tf에 반드시 포함:

```hcl
variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment 변수는 dev, prod 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵"
  type        = map(string)
  default     = {}
}
```

## 리소스 명명 규칙

```
{project_name}-{environment}-{resource_type}
예: my-project-prod-rds-instance
```

## 공통 태그 패턴

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "YYYY-MM-DD"
  }
}
```

## 환경별 필수 설정

| 항목 | dev | prod |
|------|-----|------|
| `force_destroy` | `true` | `false` |
| `deletion_protection` | `false` | `true` |
| `prevent_destroy` | 없음 | **필수** |
| Multi-AZ | 단일/2AZ | Multi-AZ (3AZ) |
| KMS 암호화 | 선택 | **필수** |
| CloudWatch 알람 | 비활성화 | 활성화 |
| 백업 보존 기간 | 최단 | 최장 |

## backend.tf 패턴

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "{env}/{module}/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "my-company-terraform-locks"
  }
}
```

## 절대 하지 말 것

- `*.tfvars` 파일 Git 커밋 (*.tfvars.example만 허용)
- prod 환경 stateful 리소스에 `prevent_destroy` 없이 정의
- 단일 상태 파일로 모든 리소스 관리
- prod 적용 시 플랜 파일 검토 없이 `terraform apply`

## Makefile 표준 타겟

```makefile
make init ENV=dev        # terraform init
make plan ENV=dev        # terraform plan
make apply ENV=prod      # terraform apply
make destroy ENV=dev     # terraform destroy (dev만)
make fmt                 # terraform fmt -recursive
make validate            # terraform validate
make output ENV=dev      # terraform output
```

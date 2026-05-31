### =============================================================================
### bootstrap/main.tf
### Terraform 원격 상태 저장소 부트스트랩
###
### Terragrunt 를 사용하기 전에 이 모듈을 먼저 실행하여
### S3 버킷과 DynamoDB 테이블을 생성합니다.
###
### 실행 방법:
###   cd bootstrap
###   terraform init
###   terraform apply
###
### ⚠️  이 모듈 자체는 로컬 상태를 사용합니다 (bootstrap 특성상 원격 상태 불가).
###     terraform.tfstate 파일을 안전한 곳에 보관하거나 Git에 추가하지 마세요.
### =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (S3 버킷, DynamoDB 테이블 이름에 사용)"
  type        = string
  default     = "terraform-practice"
}

### -----------------------------------------------------------------------
### Terraform 상태 저장 S3 버킷
### -----------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate"

  # ⚠️  이 버킷은 절대 삭제하면 안 됩니다.
  #     삭제 시 모든 Terraform 상태 파일이 유실됩니다.
  force_destroy = false

  tags = {
    Name      = "${var.project_name}-tfstate"
    ManagedBy = "terraform-bootstrap"
    Purpose   = "Terraform 원격 상태 저장"
  }
}

# 버전 관리 활성화: 상태 파일 변경 이력 보존 (잘못된 apply 복구 가능)
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 서버 사이드 암호화: 상태 파일에 저장된 민감 정보 보호
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 액세스 차단: 상태 파일 외부 노출 방지
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### -----------------------------------------------------------------------
### Terraform 상태 잠금 DynamoDB 테이블
### 동시 apply 충돌 방지 (분산 락)
### -----------------------------------------------------------------------
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "${var.project_name}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"   # 사용량 기반 과금 (비용 최소화)
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "${var.project_name}-tfstate-lock"
    ManagedBy = "terraform-bootstrap"
    Purpose   = "Terraform 상태 잠금"
  }
}

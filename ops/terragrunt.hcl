### =============================================================================
### terragrunt.hcl — Terragrunt 루트 설정
###
### 이 파일이 하는 일:
###   1. remote_state  — S3 백엔드를 모든 하위 모듈에 자동 적용
###   2. generate "provider" — provider.tf + terraform 블록 자동 생성
###   3. inputs — project_name / aws_region / environment / common_tags 공통 전달
###
### ┌─────────────────────────────────────────────────────────────┐
###  전제 조건: bootstrap/ 디렉토리를 먼저 실행하여
###            S3 버킷과 DynamoDB 테이블을 생성해야 합니다.
###
###  cd ops/bootstrap && terraform init && terraform apply
### └─────────────────────────────────────────────────────────────┘
###
### 사용 방법:
###   # 단일 모듈 실행
###   cd ops/live/nonprod/ap-northeast-2/dev/vpc && terragrunt plan
###
###   # 환경 전체 실행 (의존성 순서 자동 처리)
###   terragrunt run-all plan  --terragrunt-working-dir ops/live/nonprod/ap-northeast-2/dev/
###   terragrunt run-all apply --terragrunt-working-dir ops/live/nonprod/ap-northeast-2/dev/
### =============================================================================

locals {
  project_name = "terraform-practice"

  # live/<account>/<region>/<environment>/<component> 계층에서
  # 계정, 리전, 환경 정보를 자동 감지합니다.
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.account_id
  aws_region   = local.region_vars.locals.aws_region
  environment  = local.env_vars.locals.environment
  owner        = local.env_vars.locals.owner
  cost_center  = local.env_vars.locals.cost_center
}

### -----------------------------------------------------------------------
### 원격 상태(Remote State) 설정
###
### 상태 파일 경로 패턴: live/{account}/{region}/{env}/{module}/terraform.tfstate
###   live/nonprod/ap-northeast-2/dev/vpc/terraform.tfstate
###   live/nonprod/ap-northeast-2/dev/kms/rds/terraform.tfstate
###   live/prod/ap-northeast-2/prod/rds/terraform.tfstate
###
### path_relative_to_include() 가 각 terragrunt.hcl의 상대 경로를 자동 계산
### -----------------------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.project_name}-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "${local.project_name}-tfstate-lock"
  }
}

### -----------------------------------------------------------------------
### AWS Provider + Terraform 버전 블록 자동 생성
###
### 각 모듈의 .terragrunt-cache/ 디렉토리 안에 provider.tf 를 생성합니다.
### 모듈 소스 코드를 직접 수정하지 않고 provider 를 주입하는 핵심 기능.
### -----------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
### Terragrunt 자동 생성 파일 — 직접 수정하지 마세요.
### 루트 terragrunt.hcl 의 generate "provider" 블록에서 생성됩니다.

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Account     = "${local.account_name}"
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
      Owner       = "${local.owner}"
    }
  }
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}

### -----------------------------------------------------------------------
### 공통 inputs — 아래 값들이 모든 하위 모듈에 자동으로 전달됩니다.
### 각 모듈의 variables.tf 에 동일한 이름의 변수가 선언되어 있어야 합니다.
### -----------------------------------------------------------------------
inputs = {
  project_name = local.project_name
  aws_region   = local.aws_region
  environment  = local.environment
  owner        = local.owner

  common_tags = {
    Project     = local.project_name
    Account     = local.account_name
    Environment = local.environment
    ManagedBy   = "terragrunt"
    Owner       = local.owner
    CostCenter  = local.cost_center
  }
}

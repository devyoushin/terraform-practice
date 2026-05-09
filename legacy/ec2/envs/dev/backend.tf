###############################################
# envs/dev/backend.tf
# Terraform 상태 파일 원격 저장소 설정 (S3)
#
# ※ 사전 준비:
#   1. S3 버킷 생성 (버전 관리 활성화)
#   2. DynamoDB 테이블 생성 (상태 잠금용, PK: LockID)
###############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # ← 실제 S3 버킷 이름으로 변경
    key            = "dev/ec2/terraform.tfstate"    # 상태 파일 경로 (환경별로 다르게)
    region         = "ap-northeast-2"               # ← 버킷이 위치한 리전
    dynamodb_table = "terraform-state-lock"         # ← 실제 DynamoDB 테이블 이름으로 변경
    encrypt        = true
  }
}

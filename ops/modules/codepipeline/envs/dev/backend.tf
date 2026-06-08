###############################################
# envs/dev/backend.tf
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
    key            = "dev/codepipeline/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-state-lock"         # ← 실제 DynamoDB 테이블 이름으로 변경
    encrypt        = true
  }
}

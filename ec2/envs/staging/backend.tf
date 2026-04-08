terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"   # ← 실제 S3 버킷 이름으로 변경
    key            = "staging/ec2/terraform.tfstate" # dev와 경로가 다름
    region         = "ap-northeast-2"                # ← 버킷 리전
    dynamodb_table = "terraform-state-lock"          # ← DynamoDB 테이블 이름
    encrypt        = true
  }
}

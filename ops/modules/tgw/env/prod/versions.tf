terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # [변경] 배포 리전

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "mycompany"   # [변경] 프로젝트명
      Environment = "prod"
    }
  }
}

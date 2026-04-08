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
  region = "ap-northeast-2" # [변경] 리소스를 배포할 리전

  # 이 프로바이더로 생성되는 모든 리소스에 자동으로 붙는 태그
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "mycompany"   # [변경] 프로젝트명
      Environment = "dev"
    }
  }
}

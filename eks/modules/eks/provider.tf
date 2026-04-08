# Child module의 provider 버전 요구사항 선언
# provider 블록은 root module(envs/dev/main.tf)에서만 선언합니다.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

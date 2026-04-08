terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  # ─────────────────────────────────────────────────────────────────
  # [필수 - 팀/협업 환경] S3 원격 백엔드 설정
  #
  # 혼자 테스트할 때는 로컬 상태 파일(.tfstate)을 사용하므로 주석 유지.
  # 팀 협업 또는 운영 환경에서는 반드시 아래 주석을 해제하고 값을 채워야 합니다.
  #
  # 사전 준비:
  #   1. S3 버킷 생성 (버전 관리 활성화 권장)
  #      aws s3api create-bucket --bucket <버킷이름> --region ap-northeast-2 \
  #        --create-bucket-configuration LocationConstraint=ap-northeast-2
  #      aws s3api put-bucket-versioning --bucket <버킷이름> \
  #        --versioning-configuration Status=Enabled
  #
  #   2. DynamoDB 테이블 생성 (동시 apply 잠금용, 파티션 키: LockID, 타입: String)
  #      aws dynamodb create-table --table-name terraform-state-lock \
  #        --attribute-definitions AttributeName=LockID,AttributeType=S \
  #        --key-schema AttributeName=LockID,KeyType=HASH \
  #        --billing-mode PAY_PER_REQUEST --region ap-northeast-2
  # ─────────────────────────────────────────────────────────────────
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"  # [변경] 위에서 만든 S3 버킷 이름
  #   key            = "network/transit-gateway/terraform.tfstate"  # 상태 파일 경로 (자유롭게 지정)
  #   region         = "ap-northeast-2"               # [변경] 버킷이 있는 리전
  #   encrypt        = true                           # 상태 파일 서버사이드 암호화 (권장)
  #   dynamodb_table = "terraform-state-lock"         # [변경] 위에서 만든 DynamoDB 테이블 이름
  # }
}

provider "aws" {
  region = var.aws_region

  # default_tags: 이 프로바이더로 생성되는 모든 리소스에 자동으로 붙는 태그
  # terraform.tfvars의 project, environment 값이 여기에 반영됩니다.
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project
      Environment = var.environment
    }
  }
}

# ─────────────────────────────────────────────────────────────────
# [선택 - TGW 리전 간 피어링 시] 피어 리전 프로바이더
#
# 서울(ap-northeast-2) ↔ 버지니아(us-east-1) 처럼
# 다른 리전의 TGW와 피어링할 때 활성화합니다.
# 활성화 후 tgw-peering 모듈에서 provider = aws.peer_region 으로 참조.
# ─────────────────────────────────────────────────────────────────
# provider "aws" {
#   alias  = "peer_region"
#   region = "us-east-1"  # [변경] 피어링할 상대 리전
# }

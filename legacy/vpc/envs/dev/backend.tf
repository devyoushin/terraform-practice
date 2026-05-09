###############################################
# envs/dev/backend.tf
# Terraform 상태 파일 원격 저장소 설정
###############################################

# 기본값: 로컬 백엔드 (즉시 사용 가능)
# 팀 협업 시 아래 S3 백엔드 주석을 해제하세요.

# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"   # ← 실제 S3 버킷명으로 변경
#     key            = "dev/vpc/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "terraform-state-lock"  # ← DynamoDB 테이블명으로 변경
#     encrypt        = true
#   }
# }

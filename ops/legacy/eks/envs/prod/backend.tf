# ============================================================
# 기본값: 로컬 백엔드
# prod 환경은 반드시 S3 원격 백엔드 사용을 권장합니다.
# ============================================================

# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"
#     key            = "prod/eks/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "your-tfstate-lock"
#     encrypt        = true
#   }
# }

# ============================================================
# 기본값: 로컬 백엔드
# 팀 협업 시 아래 S3 백엔드 주석을 해제하세요.
# ============================================================

# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"
#     key            = "staging/eks/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "your-tfstate-lock"
#     encrypt        = true
#   }
# }

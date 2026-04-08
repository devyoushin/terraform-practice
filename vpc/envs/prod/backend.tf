###############################################
# envs/prod/backend.tf
# prod 환경은 반드시 S3 원격 백엔드 사용을 권장합니다.
###############################################

# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"
#     key            = "prod/vpc/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }

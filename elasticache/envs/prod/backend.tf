###
### prod 환경 - Terraform 백엔드 설정
###

# terraform {
#   backend "s3" {
#     bucket         = "my-project-terraform-state"
#     key            = "prod/elasticache/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "my-project-terraform-lock"
#   }
# }

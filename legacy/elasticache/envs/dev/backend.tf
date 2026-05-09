###
### dev 환경 - Terraform 백엔드 설정
### 팀 협업 시 S3 원격 백엔드 사용 권장
###

# terraform {
#   backend "s3" {
#     bucket         = "my-project-terraform-state"
#     key            = "dev/elasticache/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "my-project-terraform-lock"
#   }
# }

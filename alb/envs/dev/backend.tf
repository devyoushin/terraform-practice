###
### dev 환경 - Terraform 백엔드 설정
### 팀 협업 시 S3 원격 백엔드 사용 권장
### 아래 주석을 해제하고 버킷 이름, 리전을 실제 값으로 변경하세요
###

# terraform {
#   backend "s3" {
#     bucket         = "my-project-terraform-state"
#     key            = "dev/alb/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#
#     # DynamoDB 상태 잠금 (선택 사항, 동시 실행 방지)
#     dynamodb_table = "my-project-terraform-lock"
#   }
# }

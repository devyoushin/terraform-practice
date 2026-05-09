###############################################################################
### DEV 환경 Terraform 백엔드 설정
### - 로컬 상태 파일 사용 시 아래 블록 전체 주석 처리
### - S3 원격 백엔드 사용 시 주석 해제 후 버킷/키 값 수정
###############################################################################

# terraform {
#   backend "s3" {
#     bucket         = "my-project-terraform-state"
#     key            = "iam/dev/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#
#     # DynamoDB 잠금 테이블 (선택 - 동시 실행 방지)
#     dynamodb_table = "my-project-terraform-lock"
#   }
# }

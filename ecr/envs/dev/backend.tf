### =============================================================================
### envs/dev/backend.tf
### Terraform 상태 파일(tfstate) 백엔드 설정
###
### [사용 방법]
### 1. 아래 주석을 해제합니다.
### 2. bucket: Terraform 상태 저장용 S3 버킷 이름으로 변경합니다.
### 3. dynamodb_table: 상태 잠금용 DynamoDB 테이블 이름으로 변경합니다.
### 4. `terraform init -reconfigure` 명령으로 백엔드를 초기화합니다.
### =============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "my-company-prod-tfstate"
#     key            = "dev/ecr/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

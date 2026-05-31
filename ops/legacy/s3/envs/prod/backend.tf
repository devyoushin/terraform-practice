### =============================================================================
### envs/prod/backend.tf
### Terraform 상태 파일(tfstate) 백엔드 설정
###
### [사용 방법]
### 1. 아래 주석을 해제합니다.
### 2. bucket: Terraform 상태 저장용 S3 버킷 이름으로 변경합니다.
###    (README.md의 "Terraform 상태 파일 저장용 버킷 생성 예시" 참고)
### 3. dynamodb_table: 상태 잠금용 DynamoDB 테이블 이름으로 변경합니다.
### 4. `terraform init -reconfigure` 명령으로 백엔드를 초기화합니다.
### =============================================================================

# terraform {
#   backend "s3" {
#     ### S3 버킷 설정 (my-company-prod-tfstate 버킷을 미리 생성해야 합니다)
#     bucket = "my-company-prod-tfstate"
#     key    = "prod/s3/terraform.tfstate"
#     region = "ap-northeast-2"
#
#     ### 상태 파일 암호화 활성화
#     encrypt = true
#
#     ### DynamoDB를 이용한 상태 잠금 (동시 수정 방지)
#     ### DynamoDB 테이블의 파티션 키는 반드시 "LockID"(String)여야 합니다.
#     dynamodb_table = "terraform-state-lock"
#   }
# }

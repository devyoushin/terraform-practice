### ============================================================
### envs/staging/backend.tf
### 스테이징 환경 Terraform 상태 백엔드 설정
### 로컬 개발 시: 아래 주석 해제 후 S3 버킷/DynamoDB 테이블 생성 필요
### ============================================================

### S3 원격 백엔드 설정 (팀 협업 시 활성화 권장)
### 활성화 방법:
###   1. S3 버킷 생성: your-tfstate-bucket
###   2. DynamoDB 테이블 생성: terraform-state-lock (파티션키: LockID)
###   3. 아래 주석 해제 후 `terraform init` 재실행
# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"
#     key            = "staging/rds/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }

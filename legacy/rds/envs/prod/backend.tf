### ============================================================
### envs/prod/backend.tf
### 프로덕션 환경 Terraform 상태 백엔드 설정
### 중요: prod 환경은 반드시 원격 백엔드를 사용해야 합니다
### ============================================================

### S3 원격 백엔드 설정 (prod 환경에서는 활성화 필수)
### 활성화 방법:
###   1. S3 버킷 생성: your-tfstate-bucket (버저닝 활성화 권장)
###   2. DynamoDB 테이블 생성: terraform-state-lock (파티션키: LockID)
###   3. 아래 주석 해제 후 `terraform init` 재실행
# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"
#     key            = "prod/rds/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }

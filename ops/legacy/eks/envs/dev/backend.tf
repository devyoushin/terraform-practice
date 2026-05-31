# ============================================================
# 기본값: 로컬 백엔드 (terraform init 즉시 사용 가능)
# terraform.tfstate 파일이 로컬에 생성됩니다.
# ============================================================

# ============================================================
# 팀 협업 / CI-CD 사용 시: S3 원격 백엔드로 교체하세요.
#
# 사전 준비 (AWS CLI로 실행):
#   aws s3 mb s3://<버킷명> --region ap-northeast-2
#   aws dynamodb create-table \
#     --table-name <테이블명> \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST \
#     --region ap-northeast-2
#
# 아래 주석을 해제하고 bucket / dynamodb_table 값을 채우세요:
# ============================================================
# terraform {
#   backend "s3" {
#     bucket         = "your-tfstate-bucket"  # ← 실제 S3 버킷명으로 변경
#     key            = "dev/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "your-tfstate-lock"    # ← DynamoDB 테이블명으로 변경
#     encrypt        = true
#   }
# }

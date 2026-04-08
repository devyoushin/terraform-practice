###
### dev 환경 - Terraform 백엔드 설정
### S3 원격 백엔드로 팀 협업 시 상태 파일을 공유합니다.
###
### 사전 준비 (최초 1회):
###   aws s3api create-bucket \
###     --bucket <버킷이름> \
###     --region ap-northeast-2 \
###     --create-bucket-configuration LocationConstraint=ap-northeast-2
###
###   aws s3api put-bucket-versioning \
###     --bucket <버킷이름> \
###     --versioning-configuration Status=Enabled
###
###   aws dynamodb create-table \
###     --table-name terraform-state-lock \
###     --attribute-definitions AttributeName=LockID,AttributeType=S \
###     --key-schema AttributeName=LockID,KeyType=HASH \
###     --billing-mode PAY_PER_REQUEST \
###     --region ap-northeast-2
###
### 주의: backend 블록 안에는 변수(var.)를 쓸 수 없습니다.
###       환경별로 key 경로만 다르게 하여 상태 파일을 분리합니다.
###

terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"        # [변경] S3 버킷 이름
    key            = "network/tgw/dev/terraform.tfstate" # dev 환경 상태 파일 경로 (고정)
    region         = "ap-northeast-2"                   # [변경] 버킷이 위치한 리전
    encrypt        = true
    dynamodb_table = "terraform-state-lock"             # [변경] DynamoDB 잠금 테이블 이름
  }
}

###
### prod 환경 - Terraform 백엔드 설정
### S3 원격 백엔드로 팀 협업 시 상태 파일을 공유합니다.
### dev와 key 경로만 다릅니다. 버킷/테이블은 공유해도 됩니다.
###
### 주의: backend 블록 안에는 변수(var.)를 쓸 수 없습니다.
###       환경별로 key 경로만 다르게 하여 상태 파일을 분리합니다.
###

terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"         # [변경] S3 버킷 이름
    key            = "network/tgw/prod/terraform.tfstate" # prod 환경 상태 파일 경로 (고정)
    region         = "ap-northeast-2"                    # [변경] 버킷이 위치한 리전
    encrypt        = true
    dynamodb_table = "terraform-state-lock"              # [변경] DynamoDB 잠금 테이블 이름
  }
}

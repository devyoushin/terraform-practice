### =============================================================================
### dev/iam/terragrunt.hcl
### DEV 환경 IAM — EC2 인스턴스 역할 (ec2-role)
###
### 역할: EC2 인스턴스가 S3, SSM 등 AWS 서비스에 접근할 때 사용하는 IAM Role 생성
### 생성 리소스:
###   - IAM Role (EC2 서비스 신뢰 정책)
###   - IAM Instance Profile
###   - S3 버킷 접근 정책 (지정된 버킷에 한정)
###   - SSM Session Manager 정책 (bastion SSH 대체)
### DEV 특징:
###   - 의존성 없음 (독립적으로 먼저 배포 가능)
###   - s3_bucket_arns에 dev 환경 버킷 ARN 목록 지정
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../iam/modules/ec2-role"
}

inputs = {
  # ---------------------------------------------------------------
  # S3 버킷 접근 권한
  # EC2 인스턴스가 읽기/쓰기할 S3 버킷 ARN 목록
  # 실제 운영 시에는 s3/assets, s3/logs 버킷의 ARN으로 교체
  # 예시: ["arn:aws:s3:::terraform-practice-dev-assets", ...]
  # ---------------------------------------------------------------
  s3_bucket_arns = [
    "arn:aws:s3:::terraform-practice-dev-assets",
    "arn:aws:s3:::terraform-practice-dev-assets/*",
    "arn:aws:s3:::terraform-practice-dev-logs",
    "arn:aws:s3:::terraform-practice-dev-logs/*",
  ]
}

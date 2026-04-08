### =============================================================================
### modules/s3/outputs.tf
### S3 모듈 출력값 정의
### =============================================================================

output "bucket_id" {
  description = "S3 버킷 이름 (버킷 ID). 다른 리소스에서 버킷을 참조할 때 사용합니다."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 버킷 ARN. IAM 정책에서 버킷 접근 권한을 부여할 때 사용합니다."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "S3 버킷의 글로벌 도메인 이름. (예: my-bucket.s3.amazonaws.com)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 버킷의 리전별 도메인 이름. CloudFront Origin 설정 시 이 값을 사용하는 것을 권장합니다."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "S3 버킷이 생성된 AWS 리전."
  value       = aws_s3_bucket.this.region
}

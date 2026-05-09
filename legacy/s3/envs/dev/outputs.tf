### =============================================================================
### envs/dev/outputs.tf
### 개발(dev) 환경 출력값 정의
### =============================================================================

### -----------------------------------------------------------------------------
### assets 버킷 출력값
### -----------------------------------------------------------------------------
output "assets_bucket_id" {
  description = "dev 환경 assets S3 버킷 이름"
  value       = module.assets_bucket.bucket_id
}

output "assets_bucket_arn" {
  description = "dev 환경 assets S3 버킷 ARN"
  value       = module.assets_bucket.bucket_arn
}

### -----------------------------------------------------------------------------
### logs 버킷 출력값
### -----------------------------------------------------------------------------
output "logs_bucket_id" {
  description = "dev 환경 logs S3 버킷 이름"
  value       = module.logs_bucket.bucket_id
}

output "logs_bucket_arn" {
  description = "dev 환경 logs S3 버킷 ARN"
  value       = module.logs_bucket.bucket_arn
}

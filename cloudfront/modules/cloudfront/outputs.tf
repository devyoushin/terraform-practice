output "distribution_id" {
  description = "CloudFront 배포 ID. 캐시 무효화 시 사용합니다. (aws cloudfront create-invalidation --distribution-id ...)"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront 배포 ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront 배포 도메인 이름. (예: d1234567890abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront 호스팅 존 ID. Route53 Alias 레코드 설정 시 사용합니다. (고정값: Z2FDTNDATAQYW2)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "oac_id" {
  description = "Origin Access Control ID. S3 버킷 정책에서 CloudFront OAC를 허용할 때 사용합니다."
  value       = length(aws_cloudfront_origin_access_control.s3_oac) > 0 ? aws_cloudfront_origin_access_control.s3_oac[0].id : null
}

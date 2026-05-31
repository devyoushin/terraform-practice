output "distribution_id" { value = module.cdn.distribution_id; description = "CloudFront 배포 ID" }
output "domain_name" { value = module.cdn.domain_name; description = "CloudFront 도메인 이름" }
output "oac_id" { value = module.cdn.oac_id; description = "OAC ID (S3 버킷 정책 설정 시 사용)" }

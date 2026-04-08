output "distribution_id" { value = module.cdn.distribution_id; description = "CloudFront 배포 ID" }
output "domain_name" { value = module.cdn.domain_name; description = "CloudFront 도메인 이름" }
output "hosted_zone_id" { value = module.cdn.hosted_zone_id; description = "Route53 Alias 레코드 설정 시 사용" }
output "oac_id" { value = module.cdn.oac_id; description = "OAC ID" }

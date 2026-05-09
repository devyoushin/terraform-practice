output "primary_endpoint_address" { value = module.elasticache.primary_endpoint_address; description = "Redis Primary 엔드포인트" }
output "reader_endpoint_address"  { value = module.elasticache.reader_endpoint_address;  description = "Redis Reader 엔드포인트" }
output "security_group_id"        { value = module.elasticache.security_group_id;        description = "Redis 보안 그룹 ID" }
output "port"                     { value = module.elasticache.port;                     description = "Redis 포트" }

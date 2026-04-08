output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = module.transit_gateway.id
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN"
  value       = module.transit_gateway.arn
}

output "transit_gateway_owner_id" {
  description = "Transit Gateway 소유자 AWS 계정 ID"
  value       = module.transit_gateway.owner_id
}

output "transit_gateway_association_default_route_table_id" {
  description = "TGW 기본 연결 라우트 테이블 ID"
  value       = module.transit_gateway.association_default_route_table_id
}

output "route_table_ids" {
  description = "생성된 TGW 라우트 테이블 ID 맵"
  value       = { for k, v in module.tgw_route_tables : k => v.id }
}

output "vpc_attachment_ids" {
  description = "생성된 VPC 어태치먼트 ID 맵"
  value       = { for k, v in module.vpc_attachments : k => v.attachment_id }
}

output "vpn_connection_ids" {
  description = "생성된 VPN 연결 ID 맵"
  value       = { for k, v in module.vpn_connections : k => v.vpn_connection_id }
}

output "ram_resource_share_arn" {
  description = "RAM 리소스 공유 ARN (RAM 공유가 활성화된 경우)"
  value       = var.enable_ram_sharing ? module.ram[0].resource_share_arn : null
}

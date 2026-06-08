output "transit_gateway_id" {
  value = module.tgw.transit_gateway_id
}

output "vpc_attachment_ids" {
  value = module.tgw.vpc_attachment_ids
}

output "route_table_ids" {
  value = module.tgw.route_table_ids
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association = var.default_route_table_association ? "enable" : "disable"
  default_route_table_propagation = var.default_route_table_propagation ? "enable" : "disable"
  dns_support                     = var.dns_support ? "enable" : "disable"
  vpn_ecmp_support                = var.vpn_ecmp_support ? "enable" : "disable"
  multicast_support               = var.multicast_support ? "enable" : "disable"

  tags = merge(var.tags, { Name = var.name })
}

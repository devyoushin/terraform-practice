output "vpn_connection_id" {
  description = "VPN 연결 ID"
  value       = aws_vpn_connection.this.id
}

output "transit_gateway_attachment_id" {
  description = "VPN TGW 어태치먼트 ID"
  value       = aws_vpn_connection.this.transit_gateway_attachment_id
}

output "tunnel1_address" {
  description = "터널1 외부 IP 주소"
  value       = aws_vpn_connection.this.tunnel1_address
}

output "tunnel2_address" {
  description = "터널2 외부 IP 주소"
  value       = aws_vpn_connection.this.tunnel2_address
}

output "tunnel1_cgw_inside_address" {
  description = "터널1 고객 측 내부 IP"
  value       = aws_vpn_connection.this.tunnel1_cgw_inside_address
}

output "tunnel2_cgw_inside_address" {
  description = "터널2 고객 측 내부 IP"
  value       = aws_vpn_connection.this.tunnel2_cgw_inside_address
}

output "tunnel1_vgw_inside_address" {
  description = "터널1 AWS 측 내부 IP"
  value       = aws_vpn_connection.this.tunnel1_vgw_inside_address
}

output "tunnel2_vgw_inside_address" {
  description = "터널2 AWS 측 내부 IP"
  value       = aws_vpn_connection.this.tunnel2_vgw_inside_address
}

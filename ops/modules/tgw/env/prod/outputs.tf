# ──────────────────────────────────────────────────────────────
# prod 환경 TGW 배포 결과 출력값
#
# 확인 방법:
#   terraform output
#   terraform output -json  (JSON 형태로 전체 출력)
# ──────────────────────────────────────────────────────────────

output "transit_gateway_id" {
  description = "prod TGW ID. 다른 계정 VPC 어태치먼트 생성, RAM 공유, TGW 피어링 시 필요합니다."
  value       = module.tgw.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "prod TGW ARN."
  value       = module.tgw.transit_gateway_arn
}

output "route_table_ids" {
  description = "생성된 TGW 라우트 테이블 ID 맵."
  value       = module.tgw.route_table_ids
}

output "vpc_attachment_ids" {
  description = "생성된 VPC 어태치먼트 ID 맵."
  value       = module.tgw.vpc_attachment_ids
}

output "vpn_connection_ids" {
  description = "생성된 VPN 연결 ID 맵. VPN이 없으면 빈 맵."
  value       = module.tgw.vpn_connection_ids
}

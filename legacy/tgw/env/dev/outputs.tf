# ──────────────────────────────────────────────────────────────
# dev 환경 TGW 배포 결과 출력값
#
# terraform apply 완료 후 아래 명령으로 확인:
#   terraform output
#   terraform output transit_gateway_id
# ──────────────────────────────────────────────────────────────

output "transit_gateway_id" {
  description = "dev TGW ID. 다른 계정에서 어태치먼트를 만들 때 필요합니다."
  value       = module.tgw.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "dev TGW ARN. RAM 공유 설정 시 필요합니다."
  value       = module.tgw.transit_gateway_arn
}

output "route_table_ids" {
  description = "생성된 TGW 라우트 테이블 ID 맵. 수동으로 어태치먼트를 연결할 때 사용합니다."
  value       = module.tgw.route_table_ids
}

output "vpc_attachment_ids" {
  description = "생성된 VPC 어태치먼트 ID 맵."
  value       = module.tgw.vpc_attachment_ids
}

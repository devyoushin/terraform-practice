locals {
  # 모든 리소스 이름의 접두어: "<project>-<environment>"
  # 예: project="acme", environment="prod" → "acme-prod"
  name_prefix = "${var.project}-${var.environment}"
}

# ─────────────────────────────────────────
# Transit Gateway (핵심 리소스)
# ─────────────────────────────────────────
# TGW 자체를 생성합니다. 리전당 1개 권장.
# 생성 후 ID는 outputs.tf를 통해 확인할 수 있습니다.
module "transit_gateway" {
  source = "./modules/transit-gateway"

  name        = "${local.name_prefix}-tgw"
  description = "${var.project} ${var.environment} Transit Gateway"

  amazon_side_asn                 = var.tgw_amazon_side_asn
  auto_accept_shared_attachments  = var.tgw_auto_accept_shared_attachments
  default_route_table_association = var.tgw_default_route_table_association
  default_route_table_propagation = var.tgw_default_route_table_propagation
  dns_support                     = var.tgw_dns_support
  vpn_ecmp_support                = var.tgw_vpn_ecmp_support
  multicast_support               = var.tgw_multicast_support

  tags = var.tags
}

# ─────────────────────────────────────────
# TGW Route Tables (라우트 테이블)
# ─────────────────────────────────────────
# terraform.tfvars의 tgw_route_tables에 정의된 수만큼 생성됩니다.
# 각 라우트 테이블은 특정 VPC 그룹(prod, dev, shared 등)의 라우팅 정책을 담당합니다.
module "tgw_route_tables" {
  source = "./modules/tgw-route-table"

  # tgw_route_tables의 각 항목에 대해 반복 실행
  for_each = var.tgw_route_tables

  transit_gateway_id = module.transit_gateway.id
  name               = "${local.name_prefix}-${each.value.name}"
  tags               = merge(var.tags, each.value.tags)
}

# ─────────────────────────────────────────
# VPC Attachments (VPC 연결)
# ─────────────────────────────────────────
# terraform.tfvars의 vpc_attachments에 정의된 수만큼 VPC가 TGW에 연결됩니다.
# 어태치먼트가 생성된 후 아래의 라우트 테이블 Association이 수행됩니다.
module "vpc_attachments" {
  source = "./modules/tgw-vpc-attachment"

  for_each = var.vpc_attachments

  name               = "${local.name_prefix}-attach-${each.key}"
  transit_gateway_id = module.transit_gateway.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids

  # 기본 라우트 테이블 자동 연결/전파 비활성화 (아래에서 수동으로 연결함)
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  appliance_mode_support = each.value.appliance_mode_support
  dns_support            = each.value.dns_support
  ipv6_support           = each.value.ipv6_support

  tags = merge(var.tags, each.value.tags)
}

# ─────────────────────────────────────────
# Route Table Associations
# 어태치먼트 → 라우트 테이블 연결
# ─────────────────────────────────────────
# 각 VPC 어태치먼트를 해당 라우트 테이블에 연결합니다.
# vpc_attachments[*].route_table_key 값이 어떤 라우트 테이블과 매핑될지 결정합니다.
#
# 예: vpc_attachments.prod.route_table_key = "prod"
#     → prod 어태치먼트가 "prod" 라우트 테이블에 연결됨
#     → prod 라우트 테이블의 경로에 따라 prod VPC 트래픽이 라우팅됨
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = var.vpc_attachments

  transit_gateway_attachment_id  = module.vpc_attachments[each.key].attachment_id
  transit_gateway_route_table_id = module.tgw_route_tables[each.value.route_table_key].id
}

# ─────────────────────────────────────────
# Route Table Propagations (경로 전파)
# ─────────────────────────────────────────
# 특정 VPC의 CIDR을 특정 라우트 테이블에 자동으로 알립니다.
# terraform.tfvars의 tgw_route_table_propagations에 정의된 설정을 실제로 적용합니다.
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.tgw_route_table_propagations

  transit_gateway_attachment_id  = module.vpc_attachments[each.value.attachment_key].attachment_id
  transit_gateway_route_table_id = module.tgw_route_tables[each.value.route_table_key].id
}

# ─────────────────────────────────────────
# Static Routes (정적 경로)
# ─────────────────────────────────────────
# 전파로 자동 학습되지 않는 경로 또는 블랙홀(명시적 차단) 경로를 추가합니다.
# terraform.tfvars의 tgw_static_routes에 정의된 설정을 실제로 적용합니다.
resource "aws_ec2_transit_gateway_route" "this" {
  for_each = var.tgw_static_routes

  transit_gateway_route_table_id = module.tgw_route_tables[each.value.route_table_key].id
  destination_cidr_block         = each.value.destination_cidr_block

  # blackhole=true이면 attachment_id를 null로 설정 (패킷 폐기)
  # blackhole=false이면 attachment_key로 지정한 VPC 어태치먼트로 전송
  transit_gateway_attachment_id = (
    each.value.blackhole ? null : module.vpc_attachments[each.value.attachment_key].attachment_id
  )
  blackhole = each.value.blackhole
}

# ─────────────────────────────────────────
# VPC Route Tables → TGW 경로 자동 추가
# ─────────────────────────────────────────
# vpc_attachments에 vpc_route_table_ids + routes_to_tgw를 설정하면
# 해당 VPC의 라우트 테이블에 "목적지 CIDR → TGW" 경로가 자동으로 추가됩니다.
#
# 예: prod VPC의 라우트 테이블에 "0.0.0.0/0 → TGW" 경로 추가
#     → prod EC2에서 나가는 모든 트래픽이 TGW로 전달됨
locals {
  # (vpc_route_table_id, cidr) 조합을 플랫 맵으로 변환
  vpc_routes = merge([
    for attach_key, attach in var.vpc_attachments : {
      for pair in setproduct(attach.vpc_route_table_ids, attach.routes_to_tgw) :
      "${attach_key}-${pair[0]}-${replace(pair[1], "/", "_")}" => {
        route_table_id         = pair[0]
        destination_cidr_block = pair[1]
      }
    }
  ]...)
}

resource "aws_route" "to_tgw" {
  for_each = local.vpc_routes

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  transit_gateway_id     = module.transit_gateway.id

  # VPC 어태치먼트가 완전히 생성된 후에 경로를 추가해야 오류가 없음
  depends_on = [module.vpc_attachments]
}

# ─────────────────────────────────────────
# VPN Connections (온프레미스 연동)
# ─────────────────────────────────────────
# terraform.tfvars의 vpn_connections가 비어 있으면 이 블록은 실행되지 않습니다.
# VPN 연결 전에 Customer Gateway를 먼저 생성해야 합니다.
module "vpn_connections" {
  source = "./modules/tgw-vpn"

  for_each = var.vpn_connections

  name               = "${local.name_prefix}-vpn-${each.key}"
  transit_gateway_id = module.transit_gateway.id

  customer_gateway_id = each.value.customer_gateway_id
  type                = each.value.type
  static_routes_only  = each.value.static_routes_only

  tunnel1_psk                = each.value.tunnel1_psk
  tunnel2_psk                = each.value.tunnel2_psk
  tunnel1_inside_cidr        = each.value.tunnel1_inside_cidr
  tunnel2_inside_cidr        = each.value.tunnel2_inside_cidr
  tunnel1_dpd_timeout_action = each.value.tunnel1_dpd_timeout_action
  tunnel2_dpd_timeout_action = each.value.tunnel2_dpd_timeout_action
  tunnel1_ike_versions       = each.value.tunnel1_ike_versions
  tunnel2_ike_versions       = each.value.tunnel2_ike_versions

  # route_table_key가 있으면 해당 TGW 라우트 테이블에 VPN 어태치먼트를 연결
  # null이면 라우트 테이블 연결 없이 VPN만 생성
  transit_gateway_route_table_id = (
    each.value.route_table_key != null
    ? module.tgw_route_tables[each.value.route_table_key].id
    : null
  )

  tags = merge(var.tags, each.value.tags)
}

# ─────────────────────────────────────────
# RAM - 멀티 어카운트 TGW 공유
# ─────────────────────────────────────────
# enable_ram_sharing = false이면 이 블록은 실행되지 않습니다 (count = 0).
# 멀티 어카운트 환경에서 다른 계정의 VPC를 이 TGW에 연결할 때 사용합니다.
#
# RAM 공유 후 상대 계정에서 해야 할 작업:
#   1. AWS 콘솔 → Resource Access Manager → 공유 초대 수락
#   2. 상대 계정에서 해당 TGW ID로 VPC 어태치먼트 생성
#   3. (auto_accept_shared_attachments=false인 경우) 이 계정에서 어태치먼트 수락
module "ram" {
  source = "./modules/tgw-ram"
  count  = var.enable_ram_sharing ? 1 : 0

  name                      = "${local.name_prefix}-tgw-share"
  transit_gateway_arn       = module.transit_gateway.arn
  principals                = var.ram_principals
  allow_external_principals = var.ram_allow_external_principals

  tags = var.tags
}

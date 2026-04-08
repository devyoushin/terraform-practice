resource "aws_vpn_connection" "this" {
  transit_gateway_id  = var.transit_gateway_id
  customer_gateway_id = var.customer_gateway_id
  type                = var.type
  static_routes_only  = var.static_routes_only
  # static_routes_only = false → BGP 동적 라우팅 (권장: 자동 장애 감지/전환)
  # static_routes_only = true  → 정적 경로만 사용 (온프레미스 장비가 BGP 미지원 시)

  # PSK(Pre-Shared Key): null이면 AWS가 자동 생성
  # 직접 지정할 경우 Secrets Manager 또는 SSM Parameter Store에서 참조 권장
  # 예: tunnel1_psk = data.aws_secretsmanager_secret_version.vpn_psk.secret_string
  tunnel1_psk = var.tunnel1_psk
  tunnel2_psk = var.tunnel2_psk

  # 터널 내부 IP: null이면 AWS가 169.254.x.x 대역에서 자동 할당
  # 온프레미스 장비가 특정 IP를 요구하는 경우에만 지정
  tunnel1_inside_cidr = var.tunnel1_inside_cidr
  tunnel2_inside_cidr = var.tunnel2_inside_cidr

  # DPD(Dead Peer Detection): 피어 연결이 끊겼을 때 동작
  # restart 권장: 자동으로 재연결을 시도하여 다운타임 최소화
  tunnel1_dpd_timeout_action = var.tunnel1_dpd_timeout_action
  tunnel2_dpd_timeout_action = var.tunnel2_dpd_timeout_action

  # CloudWatch 터널 로깅 (활성화 시 VPN 연결 문제 디버깅에 매우 유용)
  dynamic "tunnel1_log_options" {
    for_each = var.enable_tunnel_logging ? [1] : []
    content {
      cloudwatch_log_options {
        log_enabled       = true
        log_group_arn     = aws_cloudwatch_log_group.vpn_tunnel1[0].arn
        log_output_format = "json"
      }
    }
  }

  dynamic "tunnel2_log_options" {
    for_each = var.enable_tunnel_logging ? [1] : []
    content {
      cloudwatch_log_options {
        log_enabled       = true
        log_group_arn     = aws_cloudwatch_log_group.vpn_tunnel2[0].arn
        log_output_format = "json"
      }
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

# VPN 터널 로그 그룹
# 터널 상태 변화, IKE 협상 오류, DPD 타임아웃 등을 기록합니다.
resource "aws_cloudwatch_log_group" "vpn_tunnel1" {
  count = var.enable_tunnel_logging ? 1 : 0

  name              = "/aws/vpn/${var.name}/tunnel1"
  retention_in_days = var.log_retention_days # [변경] 로그 보존 기간 (일). 기본 90일.

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "vpn_tunnel2" {
  count = var.enable_tunnel_logging ? 1 : 0

  name              = "/aws/vpn/${var.name}/tunnel2"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# VPN 어태치먼트를 TGW 라우트 테이블에 연결
# route_table_key를 지정한 경우에만 실행됩니다.
# 연결 후 BGP를 사용하면 온프레미스 경로가 해당 라우트 테이블에 자동으로 전파됩니다.
resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  count = var.transit_gateway_route_table_id != null ? 1 : 0

  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

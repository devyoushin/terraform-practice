resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  # false 유지 권장: 루트 모듈에서 수동으로 라우트 테이블을 연결하기 때문
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation

  # 방화벽/NVA를 이 VPC에 배치하는 경우 enable로 설정
  # - enable: 인/아웃 트래픽이 같은 AZ의 동일 어플라이언스를 경유 (비대칭 라우팅 방지)
  # - disable: 기본값, 일반 VPC에 사용
  appliance_mode_support = var.appliance_mode_support ? "enable" : "disable"

  # 이 VPC의 프라이빗 DNS를 TGW 너머에서도 해석하려면 enable
  dns_support  = var.dns_support ? "enable" : "disable"

  # IPv6 듀얼스택 사용 시에만 enable
  ipv6_support = var.ipv6_support ? "enable" : "disable"

  tags = merge(var.tags, { Name = var.name })
}

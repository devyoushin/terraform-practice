# =================================================================
# prod 환경 Transit Gateway - Hub-and-Spoke 구성
#
# 실행 방법:
#   cd env/prod
#   terraform init
#   terraform plan
#   terraform apply
#
# prod 환경 구성:
#   - Shared VPC: 공통 서비스 (DNS, 패치, 모니터링)
#   - Egress VPC: 인터넷 출구 집중화 (NAT Gateway)
#   - Prod VPC:   운영 애플리케이션
#   - (선택) VPN: 온프레미스 데이터센터 연결
# =================================================================

locals {
  project     = "mycompany" # [변경] 프로젝트명
  environment = "prod"

  # ── prod 환경 VPC CIDR ──────────────────────────────────────────
  # [변경] 실제 운영 CIDR로 변경하세요.
  # 주의: dev 환경 CIDR과도 겹치면 안 됩니다 (추후 dev-prod TGW 피어링 고려).
  shared_vpc_cidr = "10.0.0.0/16"   # 공유 서비스 VPC
  egress_vpc_cidr = "10.1.0.0/16"   # 인터넷 출구 VPC (NAT GW 집중)
  prod_vpc_cidr   = "10.10.0.0/16"  # prod 애플리케이션 VPC
  # onprem_cidr   = "192.168.0.0/16" # [선택] 온프레미스 연결 시 추가
}

module "tgw" {
  source = "../../"

  project     = local.project
  environment = local.environment

  # ── Transit Gateway ───────────────────────────────────────────
  # [변경] dev(64513)와 다른 ASN을 사용하세요.
  tgw_amazon_side_asn = 64512

  tgw_default_route_table_association = false
  tgw_default_route_table_propagation = false
  tgw_dns_support                     = true
  tgw_vpn_ecmp_support                = true
  tgw_multicast_support               = false

  # ── TGW 라우트 테이블 ─────────────────────────────────────────
  # prod는 egress VPC를 포함한 4개 테이블로 구성합니다.
  tgw_route_tables = {
    shared = { name = "rt-shared" } # 공유 서비스 VPC용
    egress = { name = "rt-egress" } # 인터넷 출구 VPC용
    prod   = { name = "rt-prod" }   # 운영 Spoke VPC용
    # onprem = { name = "rt-onprem" } # [선택] VPN 온프레미스용
  }

  # ── VPC 어태치먼트 ────────────────────────────────────────────
  vpc_attachments = {

    # ── Shared VPC ────────────────────────────────────────────────
    shared = {
      # [변경 필수] 공유 서비스 VPC ID
      vpc_id = "vpc-0xxxxxxxxxxxxxxx1"

      # [변경 필수] Shared VPC TGW 전용 서브넷 (AZ당 1개, /28 권장)
      subnet_ids = [
        "subnet-0xxxxxxx1", # ap-northeast-2a
        "subnet-0xxxxxxx2", # ap-northeast-2b
        "subnet-0xxxxxxx3", # ap-northeast-2c
      ]

      route_table_key = "shared"

      # [변경 필수] Shared VPC 프라이빗 서브넷 라우트 테이블 ID
      # Prod, Egress VPC CIDR → TGW 경로가 여기에 자동 추가됩니다.
      vpc_route_table_ids = [
        "rtb-0xxxxxxx1",
        "rtb-0xxxxxxx2",
      ]
      routes_to_tgw = [local.prod_vpc_cidr]
    }

    # ── Egress VPC (인터넷 출구 집중화) ──────────────────────────
    # 이 VPC에 NAT Gateway가 있어야 합니다.
    # Prod VPC의 인터넷 트래픽: Prod → TGW → Egress → NAT GW → 인터넷
    egress = {
      # [변경 필수] Egress VPC ID
      vpc_id = "vpc-0xxxxxxxxxxxxxxx2"

      # [변경 필수] Egress VPC TGW 전용 서브넷
      subnet_ids = [
        "subnet-0eeeeee1",
        "subnet-0eeeeee2",
        "subnet-0eeeeee3",
      ]

      route_table_key = "egress"

      # Egress VPC 프라이빗 서브넷 라우트 테이블
      # 인터넷에서 돌아오는 응답이 NAT GW → 프라이빗 → TGW → Prod VPC 로 전달됩니다.
      # [변경 필수] Egress VPC 프라이빗 서브넷 라우트 테이블 ID
      vpc_route_table_ids = [
        "rtb-0eeeeee1",
        "rtb-0eeeeee2",
      ]
      routes_to_tgw = [local.prod_vpc_cidr, local.shared_vpc_cidr]
    }

    # ── Prod 애플리케이션 VPC ─────────────────────────────────────
    prod = {
      # [변경 필수] prod VPC ID
      vpc_id = "vpc-0xxxxxxxxxxxxxxx3"

      # [변경 필수] prod VPC TGW 전용 서브넷
      subnet_ids = [
        "subnet-0ppppppp1",
        "subnet-0ppppppp2",
        "subnet-0ppppppp3",
      ]

      route_table_key = "prod"

      # [변경 필수] prod VPC 프라이빗 서브넷 라우트 테이블 ID
      vpc_route_table_ids = [
        "rtb-0ppppppp1",
        "rtb-0ppppppp2",
        "rtb-0ppppppp3",
      ]

      # 모든 트래픽을 TGW로 전송 (인터넷은 TGW → Egress VPC 경유)
      routes_to_tgw = ["0.0.0.0/0"]
    }
  }

  # ── 라우트 전파 ───────────────────────────────────────────────
  tgw_route_table_propagations = {
    # Shared RT ← Prod CIDR 전파 (공유 서버 → prod 서버 응답 가능)
    shared_from_prod = { route_table_key = "shared", attachment_key = "prod" }

    # Egress RT ← Prod CIDR 전파 (인터넷 응답 트래픽이 prod VPC로 돌아올 수 있도록)
    egress_from_prod = { route_table_key = "egress", attachment_key = "prod" }

    # Prod RT ← Shared CIDR 전파 (prod 서버 → 공유 서버 접근 가능)
    prod_from_shared = { route_table_key = "prod", attachment_key = "shared" }
  }

  # ── 정적 경로 ─────────────────────────────────────────────────
  tgw_static_routes = {
    # Prod/Shared → 인터넷 트래픽을 Egress VPC로 전달
    # 전파로는 기본 경로(0.0.0.0/0)를 알릴 수 없어 정적으로 설정해야 합니다.
    prod_default_to_egress = {
      route_table_key        = "prod"
      destination_cidr_block = "0.0.0.0/0"
      attachment_key         = "egress"
    }
    shared_default_to_egress = {
      route_table_key        = "prod"
      destination_cidr_block = "0.0.0.0/0"
      attachment_key         = "egress"
    }
  }

  # ── VPN 연결 (온프레미스 데이터센터) ─────────────────────────
  # [선택] 온프레미스 연결이 필요한 경우 주석 해제
  #
  # 사전 준비:
  #   1. Customer Gateway 생성 (온프레미스 VPN 장비의 공인 IP와 ASN 필요)
  #      aws ec2 create-customer-gateway \
  #        --type ipsec.1 \
  #        --public-ip <온프레미스 공인IP> \
  #        --bgp-asn <온프레미스 ASN>
  #
  #   2. 생성된 Customer Gateway ID를 아래 customer_gateway_id에 입력
  # vpn_connections = {
  #   datacenter_seoul = {
  #     customer_gateway_id = "cgw-0xxxxxxxxxxxxxxxx" # [변경] Customer Gateway ID
  #     route_table_key     = "prod"  # VPN을 어떤 라우트 테이블에 붙일지
  #     static_routes_only  = false   # false = BGP 동적 라우팅 (권장)
  #     # PSK를 직접 지정하려면 아래 주석 해제 (null이면 AWS가 자동 생성)
  #     # tunnel1_psk = "your-psk-here"
  #     # tunnel2_psk = "your-psk-here"
  #     tags = { Datacenter = "seoul" }
  #   }
  # }

  # ── RAM 공유 (멀티 어카운트) ──────────────────────────────────
  # [선택] 다른 AWS 계정의 VPC를 이 TGW에 연결할 경우 활성화
  # enable_ram_sharing = true
  # ram_principals     = ["123456789012"] # [변경] 공유할 AWS 계정 ID

  # ── 공통 태그 ─────────────────────────────────────────────────
  tags = {
    CostCenter = "networking-prod" # [변경]
    Owner      = "platform-team"   # [변경]
  }
}

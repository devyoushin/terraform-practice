# =================================================================
# dev 환경 Transit Gateway
#
# 실행 방법:
#   cd env/dev
#   terraform init
#   terraform plan
#   terraform apply
#
# 이 파일에서 바꿔야 할 것들:
#   1. locals 블록의 CIDR 값 (회사 IP 대역과 겹치지 않게)
#   2. vpc_id, subnet_ids, vpc_route_table_ids (실제 VPC 리소스 ID)
#   3. versions.tf 의 S3 백엔드 설정
# =================================================================

locals {
  project     = "mycompany" # [변경] 프로젝트명 (versions.tf의 Project 태그와 동일하게)
  environment = "dev"

  # ── dev 환경 VPC CIDR 설계 ──────────────────────────────────────
  # [변경] 실제 환경 CIDR로 변경하세요.
  # 주의: TGW로 연결되는 모든 VPC의 CIDR은 서로 겹치면 안 됩니다.
  shared_vpc_cidr = "10.0.0.0/16"  # 공유 서비스 VPC (DNS, NTP, 패치 서버 등)
  dev_vpc_cidr    = "10.20.0.0/16" # dev 애플리케이션 VPC
}

# ──────────────────────────────────────────────────────────────────
# 루트 모듈 호출
# source 경로: env/dev/ 기준으로 루트 모듈(../../)을 참조합니다.
# ──────────────────────────────────────────────────────────────────
module "tgw" {
  source = "../../" # 루트 모듈 경로. Git 원격 소스로도 교체 가능.
                    # 예: source = "git::https://github.com/your-org/terraform-tgw.git?ref=v1.0.0"

  project     = local.project
  environment = local.environment

  # ── Transit Gateway 설정 ──────────────────────────────────────
  # [변경] 다른 TGW나 온프레미스 장비와 ASN이 겹치지 않도록 확인하세요.
  # prod 환경과 다른 ASN을 사용하면 추후 TGW 피어링 시 편리합니다.
  # dev: 64513 / prod: 64512 처럼 구분하는 것을 권장합니다.
  tgw_amazon_side_asn = 64513

  # 수동으로 라우트 테이블을 관리하기 위해 모두 false 유지
  tgw_default_route_table_association = false
  tgw_default_route_table_propagation = false
  tgw_dns_support                     = true
  tgw_vpn_ecmp_support                = true
  tgw_multicast_support               = false

  # ── TGW 라우트 테이블 ─────────────────────────────────────────
  # dev 환경은 shared + dev 2개 테이블로 단순하게 구성합니다.
  # (prod 환경과 달리 egress VPC가 없는 경우의 예시)
  tgw_route_tables = {
    shared = { name = "rt-shared" }
    dev    = { name = "rt-dev" }
  }

  # ── VPC 어태치먼트 ────────────────────────────────────────────
  vpc_attachments = {

    # ── Shared VPC (공유 서비스) ──────────────────────────────────
    shared = {
      # [변경 필수] AWS 콘솔 → VPC → VPC ID 복사
      # 확인 CLI: aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*shared*" \
      #             --query 'Vpcs[].VpcId'
      vpc_id = "vpc-0xxxxxxxxxxxxxxx1"

      # [변경 필수] TGW 전용 서브넷 ID (AZ당 1개, /28 권장)
      # 확인 CLI: aws ec2 describe-subnets \
      #             --filters "Name=tag:Name,Values=*tgw*" "Name=vpc-id,Values=vpc-0xxx" \
      #             --query 'Subnets[].SubnetId'
      subnet_ids = [
        "subnet-0xxxxxxx1", # ap-northeast-2a TGW 서브넷
        "subnet-0xxxxxxx2", # ap-northeast-2b TGW 서브넷
        "subnet-0xxxxxxx3", # ap-northeast-2c TGW 서브넷 (2개 AZ만 쓴다면 이 줄 삭제)
      ]

      route_table_key = "shared"

      # [변경 필수] Shared VPC의 프라이빗 서브넷 라우트 테이블 ID
      # 이 라우트 테이블에 "dev VPC CIDR → TGW" 경로가 자동으로 추가됩니다.
      # 확인 CLI: aws ec2 describe-route-tables \
      #             --filters "Name=vpc-id,Values=vpc-0xxx" \
      #             --query 'RouteTables[?Associations[?Main!=`true`]].RouteTableId'
      vpc_route_table_ids = [
        "rtb-0xxxxxxx1", # shared-private-2a 라우트 테이블
        "rtb-0xxxxxxx2", # shared-private-2b 라우트 테이블
      ]

      # Shared VPC에서 dev VPC로 가는 트래픽을 TGW로 전송
      routes_to_tgw = [local.dev_vpc_cidr]
    }

    # ── Dev 애플리케이션 VPC ──────────────────────────────────────
    dev = {
      # [변경 필수] dev VPC ID
      vpc_id = "vpc-0xxxxxxxxxxxxxxx2"

      # [변경 필수] dev VPC TGW 전용 서브넷 ID
      subnet_ids = [
        "subnet-0yyyyyyy1", # ap-northeast-2a TGW 서브넷
        "subnet-0yyyyyyy2", # ap-northeast-2b TGW 서브넷
      ]

      route_table_key = "dev"

      # [변경 필수] dev VPC 프라이빗 서브넷 라우트 테이블 ID
      vpc_route_table_ids = [
        "rtb-0yyyyyyy1", # dev-private-2a 라우트 테이블
        "rtb-0yyyyyyy2", # dev-private-2b 라우트 테이블
      ]

      # dev VPC에서 나가는 모든 트래픽을 TGW로 전송
      # 0.0.0.0/0: 인터넷 트래픽 포함 (Shared VPC에 NAT GW가 있다면 거기서 인터넷 출구)
      # Shared VPC에 NAT GW가 없다면 "10.0.0.0/16" 처럼 특정 CIDR만 입력
      routes_to_tgw = ["0.0.0.0/0"]
    }
  }

  # ── 라우트 전파 ───────────────────────────────────────────────
  # shared ↔ dev 양방향 통신을 허용합니다.
  tgw_route_table_propagations = {
    # shared 라우트 테이블 ← dev VPC CIDR 전파
    # → shared 서버에서 dev 서버로 응답 가능
    shared_from_dev = { route_table_key = "shared", attachment_key = "dev" }

    # dev 라우트 테이블 ← shared VPC CIDR 전파
    # → dev 서버에서 shared 서버(DNS, 모니터링 등)로 접근 가능
    dev_from_shared = { route_table_key = "dev", attachment_key = "shared" }
  }

  # ── 정적 경로 ─────────────────────────────────────────────────
  # [선택] Shared VPC에 NAT Gateway가 있어서 dev 인터넷 트래픽을 집중시키려면 아래 주석 해제
  # shared VPC의 NAT GW를 dev도 쓰는 구조: dev → TGW → shared → NAT GW → 인터넷
  tgw_static_routes = {
    # dev_default_to_shared = {
    #   route_table_key        = "dev"
    #   destination_cidr_block = "0.0.0.0/0"
    #   attachment_key         = "shared"
    # }
  }

  # ── 공통 태그 ─────────────────────────────────────────────────
  # [변경] 조직 태깅 정책에 맞게 수정하세요.
  tags = {
    CostCenter = "networking-dev" # [변경] 비용 센터
    Owner      = "platform-team"  # [변경] 담당 팀
  }
}

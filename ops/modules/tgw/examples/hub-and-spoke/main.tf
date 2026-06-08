# =================================================================
# Hub-and-Spoke 예제
#
# 아키텍처:
#   ┌─────────────────────────────────────────────────────┐
#   │                  Transit Gateway                     │
#   │  [RT: shared]  [RT: prod]  [RT: dev]  [RT: egress]  │
#   └──────┬──────────────┬──────────┬───────────┬────────┘
#          │              │          │           │
#   [Shared VPC]    [Prod VPC]  [Dev VPC]  [Egress VPC]
#   (공유 서비스)    (운영 Spoke) (개발 Spoke) (인터넷 출구)
#
# 라우팅 정책:
#   - Prod/Dev ↔ Shared VPC 통신 허용 (전파)
#   - Prod ↔ Dev 직접 통신 차단 (블랙홀 정적 경로)
#   - 인터넷 트래픽: Prod/Dev → TGW → Egress VPC(NAT GW) → 인터넷
#
# [사용 방법]
#   이 예제는 구조를 이해하기 위한 참고용입니다.
#   실제 사용 시에는 루트 모듈(../../)을 직접 호출하거나
#   terraform.tfvars.example을 복사해서 사용하세요.
# =================================================================

locals {
  # [변경] 프로젝트명과 환경명을 실제 값으로 변경하세요.
  project     = "mycompany"
  environment = "prod"
  region      = "ap-northeast-2" # [변경] 배포할 AWS 리전

  # ── VPC CIDR 설계 ──────────────────────────────────────────────
  # [변경] 실제 환경의 CIDR과 겹치지 않도록 설계하세요.
  # 권장: 각 VPC를 /16으로 할당하고, 그 안에서 서브넷을 /24~28로 분할
  #
  # 주의: TGW로 연결되는 VPC들의 CIDR은 절대 겹치면 안 됩니다.
  shared_vpc_cidr = "10.0.0.0/16"  # 공유 서비스 VPC (DNS, NTP, 모니터링 등)
  egress_vpc_cidr = "10.1.0.0/16"  # 인터넷 출구 VPC (NAT Gateway 집중)
  prod_vpc_cidr   = "10.10.0.0/16" # 운영 환경 VPC
  dev_vpc_cidr    = "10.20.0.0/16" # 개발 환경 VPC
}

provider "aws" {
  region = local.region
}

# ─────────────────────────────────────────────────────────────────
# VPC 생성
#
# [주의] 이 예제는 "_vpc" 라는 가상의 VPC 모듈을 참조합니다.
# 실제 환경에서는 아래 중 하나를 사용하세요:
#
#   방법 1) Terraform 공식 VPC 모듈 사용
#     source  = "terraform-aws-modules/vpc/aws"
#     version = "~> 5.0"
#
#   방법 2) 직접 만든 VPC 모듈 경로 지정
#     source = "git::https://github.com/your-org/terraform-vpc.git?ref=v1.0.0"
#
#   방법 3) 이미 존재하는 VPC라면 data 소스로 참조
#     data "aws_vpc" "prod" { id = "vpc-0xxxxxxxx" }
#     data "aws_subnets" "prod_tgw" {
#       filter { name = "tag:Name", values = ["*tgw*"] }
#       filter { name = "vpc-id",   values = [data.aws_vpc.prod.id] }
#     }
# ─────────────────────────────────────────────────────────────────

module "shared_vpc" {
  source = "../_vpc" # [변경] 실제 VPC 모듈 경로로 교체

  name       = "${local.project}-shared"
  cidr_block = local.shared_vpc_cidr
  # [변경] 사용할 가용영역 목록
  azs = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

  # [변경] 실제 서비스용 프라이빗 서브넷 CIDR
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  # TGW 전용 서브넷: /28로 작게 설정 (TGW가 AZ당 IP 1개 사용)
  # 다른 리소스와 섞지 마세요.
  tgw_subnets = ["10.0.101.0/28", "10.0.102.0/28", "10.0.103.0/28"]
}

module "egress_vpc" {
  source = "../_vpc"

  name       = "${local.project}-egress"
  cidr_block = local.egress_vpc_cidr
  azs        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

  # Egress VPC는 NAT Gateway를 위해 퍼블릭 서브넷이 필요합니다.
  # [변경] 실제 CIDR로 교체
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  tgw_subnets     = ["10.1.101.0/28", "10.1.102.0/28", "10.1.103.0/28"]

  # Egress VPC에서 인터넷으로 나가기 위해 NAT Gateway 활성화
  # NAT Gateway 비용이 발생합니다 (AZ당 약 $32/월 + 데이터 전송 비용)
  enable_nat_gateway = true
}

module "prod_vpc" {
  source = "../_vpc"

  name       = "${local.project}-prod"
  cidr_block = local.prod_vpc_cidr
  azs        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

  # Prod VPC는 인터넷 직접 출구 없이 TGW → Egress VPC 경유
  # 따라서 퍼블릭 서브넷 불필요, NAT Gateway도 불필요
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  tgw_subnets     = ["10.10.101.0/28", "10.10.102.0/28", "10.10.103.0/28"]
}

module "dev_vpc" {
  source = "../_vpc"

  name       = "${local.project}-dev"
  cidr_block = local.dev_vpc_cidr
  azs        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  tgw_subnets     = ["10.20.101.0/28", "10.20.102.0/28", "10.20.103.0/28"]
}

# ─────────────────────────────────────────────────────────────────
# Transit Gateway (루트 모듈 호출)
# ─────────────────────────────────────────────────────────────────
module "tgw" {
  source = "../../" # 루트 모듈 경로. 원격 Git 소스로도 교체 가능.

  project     = local.project
  environment = local.environment

  # BGP ASN: 이 TGW의 고유 식별자
  # [변경] 동일 네트워크 내 다른 TGW나 온프레미스 장비와 겹치지 않는 값 사용
  tgw_amazon_side_asn = 64512

  # false 유지 권장: 아래에서 수동으로 라우트 테이블을 연결하기 때문
  tgw_default_route_table_association = false
  tgw_default_route_table_propagation = false
  tgw_dns_support                     = true
  tgw_vpn_ecmp_support                = true

  # ── 라우트 테이블 정의 ──────────────────────────────────────────
  # 각 VPC 그룹별로 독립된 라우트 테이블을 만들어 트래픽을 제어합니다.
  # 키 이름(shared, prod 등)은 아래 vpc_attachments.route_table_key와 반드시 일치해야 합니다.
  #
  # [변경] VPC 구성에 맞게 라우트 테이블을 추가하거나 제거하세요.
  tgw_route_tables = {
    shared = { name = "rt-shared" } # Shared Hub VPC용
    egress = { name = "rt-egress" } # 인터넷 출구 VPC용
    prod   = { name = "rt-prod" }   # 운영 Spoke VPC용
    dev    = { name = "rt-dev" }    # 개발 Spoke VPC용
  }

  # ── VPC 어태치먼트 ──────────────────────────────────────────────
  # [변경] 연결할 VPC 목록. VPC 모듈 output을 직접 참조합니다.
  # 이미 존재하는 VPC라면 data 소스의 결과값으로 교체하세요.
  vpc_attachments = {
    shared = {
      vpc_id          = module.shared_vpc.vpc_id
      subnet_ids      = module.shared_vpc.tgw_subnet_ids # TGW 전용 서브넷
      route_table_key = "shared"

      # Shared VPC의 라우트 테이블에 Spoke CIDR → TGW 경로를 자동 추가
      # (이 설정이 없으면 Shared VPC의 EC2에서 Spoke로 패킷이 나가지 못합니다)
      vpc_route_table_ids = module.shared_vpc.private_route_table_ids
      routes_to_tgw       = [local.prod_vpc_cidr, local.dev_vpc_cidr]
    }

    egress = {
      vpc_id          = module.egress_vpc.vpc_id
      subnet_ids      = module.egress_vpc.tgw_subnet_ids
      route_table_key = "egress"

      # Egress VPC 프라이빗 서브넷 → TGW로 Spoke 응답 트래픽 반환
      # (인터넷 → NAT GW → 프라이빗 서브넷 → TGW → Spoke VPC)
      vpc_route_table_ids = module.egress_vpc.private_route_table_ids
      routes_to_tgw       = [local.prod_vpc_cidr, local.dev_vpc_cidr]
    }

    prod = {
      vpc_id          = module.prod_vpc.vpc_id
      subnet_ids      = module.prod_vpc.tgw_subnet_ids
      route_table_key = "prod"

      # Prod VPC에서 나가는 모든 트래픽(인터넷 포함)을 TGW로 전송
      # 인터넷 트래픽은 TGW → egress 라우트 테이블 → Egress VPC → 인터넷
      vpc_route_table_ids = module.prod_vpc.private_route_table_ids
      routes_to_tgw       = ["0.0.0.0/0"]
    }

    dev = {
      vpc_id          = module.dev_vpc.vpc_id
      subnet_ids      = module.dev_vpc.tgw_subnet_ids
      route_table_key = "dev"
      vpc_route_table_ids = module.dev_vpc.private_route_table_ids
      routes_to_tgw       = ["0.0.0.0/0"]
    }
  }

  # ── 라우트 전파 설정 ─────────────────────────────────────────────
  # "어떤 VPC의 CIDR을 어떤 라우트 테이블에 알릴 것인가"를 정의합니다.
  #
  # 읽는 법: { route_table_key = "A", attachment_key = "B" }
  #   → B VPC의 CIDR이 A 라우트 테이블에 전파됨
  #   → A 라우트 테이블을 가진 VPC에서 B VPC로 통신 가능
  #
  # [변경] 통신을 허용할 경로만 추가하세요.
  # 아래 설정에서 의도적으로 빠진 것: prod ↔ dev 전파 (두 환경 간 직접 통신 차단)
  tgw_route_table_propagations = {
    # Shared RT에 Prod, Dev CIDR 전파
    # → 공유 서버가 운영/개발 서버로 응답을 보낼 수 있음
    shared_from_prod = { route_table_key = "shared", attachment_key = "prod" }
    shared_from_dev  = { route_table_key = "shared", attachment_key = "dev" }

    # Egress RT에 Prod, Dev CIDR 전파
    # → NAT GW에서 돌아오는 응답이 올바른 Spoke VPC로 전달됨
    egress_from_prod = { route_table_key = "egress", attachment_key = "prod" }
    egress_from_dev  = { route_table_key = "egress", attachment_key = "dev" }

    # Prod/Dev RT에 Shared CIDR 전파
    # → Spoke VPC에서 공유 서버(DNS, 모니터링 등)로 접근 가능
    prod_from_shared = { route_table_key = "prod", attachment_key = "shared" }
    dev_from_shared  = { route_table_key = "dev", attachment_key = "shared" }
  }

  # ── 정적 경로 ───────────────────────────────────────────────────
  tgw_static_routes = {
    # 인터넷 트래픽(0.0.0.0/0)을 Egress VPC로 전달
    # 전파로는 기본 경로를 알릴 수 없기 때문에 정적으로 설정해야 합니다.
    prod_default_to_egress = {
      route_table_key        = "prod"
      destination_cidr_block = "0.0.0.0/0"
      attachment_key         = "egress"
    }
    dev_default_to_egress = {
      route_table_key        = "dev"
      destination_cidr_block = "0.0.0.0/0"
      attachment_key         = "egress"
    }
    shared_default_to_egress = {
      route_table_key        = "shared"
      destination_cidr_block = "0.0.0.0/0"
      attachment_key         = "egress"
    }

    # ── 보안: Prod ↔ Dev 명시적 차단 ──────────────────────────────
    # 전파에 prod ↔ dev를 추가하지 않았지만, 만약 다른 경로(예: 0.0.0.0/0)로
    # 우회될 수 있기 때문에 블랙홀을 명시적으로 추가합니다.
    # 블랙홀 경로는 더 구체적인 경로이므로 정적 기본 경로보다 우선합니다.
    #
    # [변경] 실제 Dev/Prod VPC CIDR로 교체하세요.
    prod_block_dev = {
      route_table_key        = "prod"
      destination_cidr_block = local.dev_vpc_cidr # Dev VPC CIDR (10.20.0.0/16)
      blackhole              = true
    }
    dev_block_prod = {
      route_table_key        = "dev"
      destination_cidr_block = local.prod_vpc_cidr # Prod VPC CIDR (10.10.0.0/16)
      blackhole              = true
    }
  }

  # [변경] 조직의 태깅 정책에 맞게 수정하세요.
  tags = {
    CostCenter = "networking"
    Owner      = "platform-team"
  }
}

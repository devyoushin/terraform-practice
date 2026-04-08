variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
  # 서울: ap-northeast-2 / 도쿄: ap-northeast-1 / 버지니아: us-east-1
}

variable "project" {
  description = "프로젝트명. 모든 리소스 이름 앞에 붙는 접두어로 사용됩니다. (예: acme → acme-prod-tgw)"
  type        = string
  # [필수] terraform.tfvars 에서 반드시 값을 지정해야 합니다.
}

variable "environment" {
  description = "배포 환경. 리소스 이름과 default_tags에 반영됩니다."
  type        = string
  # [필수] prod / staging / dev 중 하나만 허용 (아래 validation에서 검사)
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment는 prod, staging, dev 중 하나여야 합니다."
  }
}

# ─────────────────────────────────────────
# Transit Gateway
# ─────────────────────────────────────────
variable "tgw_amazon_side_asn" {
  description = "TGW의 BGP ASN. 온프레미스 장비나 다른 TGW와 중복되면 안 됩니다."
  type        = number
  default     = 64512
  # 사설 ASN 범위: 64512 ~ 65534
  # 같은 계정에 여러 TGW가 있다면 각각 다른 값 사용
}

variable "tgw_auto_accept_shared_attachments" {
  description = "RAM으로 공유된 어태치먼트 자동 수락 여부. 운영 환경에서는 false 권장."
  type        = bool
  default     = false
}

variable "tgw_default_route_table_association" {
  description = "기본 라우트 테이블 자동 연결 여부. false 권장 (수동으로 정밀 제어)."
  type        = bool
  default     = false
  # true로 설정하면 모든 VPC가 단일 라우트 테이블에 연결되어 환경 격리가 불가능해집니다.
}

variable "tgw_default_route_table_propagation" {
  description = "기본 라우트 테이블 자동 전파 여부. false 권장 (수동으로 정밀 제어)."
  type        = bool
  default     = false
}

variable "tgw_dns_support" {
  description = "VPC의 프라이빗 DNS를 TGW 너머에서도 해석 가능하게 하는 옵션. true 권장."
  type        = bool
  default     = true
}

variable "tgw_vpn_ecmp_support" {
  description = "동일 목적지에 여러 VPN 터널로 부하 분산(ECMP) 여부. true 권장."
  type        = bool
  default     = true
}

variable "tgw_multicast_support" {
  description = "멀티캐스트 지원 여부. 한번 활성화하면 TGW 삭제 전까지 비활성화 불가."
  type        = bool
  default     = false
  # 멀티캐스트가 필요한 경우(미디어 스트리밍 등)에만 true로 설정
}

# ─────────────────────────────────────────
# VPC Attachments
# ─────────────────────────────────────────
variable "vpc_attachments" {
  description = "TGW에 연결할 VPC 어태치먼트 목록. 키 이름이 라우트 전파/정적 경로의 attachment_key로 사용됩니다."
  type = map(object({
    # [필수] 연결할 VPC의 ID
    vpc_id = string

    # [필수] TGW 전용 서브넷 ID 목록 (AZ당 1개, 최소 2개 AZ 권장)
    # /28 서브넷 권장. 다른 리소스(EC2 등)와 공유하지 마세요.
    subnet_ids = list(string)

    # [필수] 이 VPC가 사용할 TGW 라우트 테이블 키 (tgw_route_tables의 키 이름과 일치해야 함)
    route_table_key = string

    # 방화벽/네트워크 가상 어플라이언스(NVA)를 이 VPC에 배치할 경우 true
    # 같은 AZ의 인/아웃 트래픽이 동일 어플라이언스 인스턴스를 통과하도록 보장
    appliance_mode_support = optional(bool, false)

    # 이 VPC의 프라이빗 DNS를 TGW 너머에서도 해석 가능하게 함
    dns_support = optional(bool, true)

    # IPv6 듀얼스택이 필요한 경우에만 true
    ipv6_support = optional(bool, false)

    # ── VPC 내부 라우트 테이블 자동 업데이트 ──
    # vpc_route_table_ids: 이 VPC에서 경로를 추가할 라우트 테이블 ID 목록
    # routes_to_tgw: 위 라우트 테이블에 "X.X.X.X/X → TGW" 형태로 추가할 CIDR 목록
    # 두 값을 모두 설정하면 Terraform이 VPC 라우트 테이블에 자동으로 경로를 추가합니다.
    vpc_route_table_ids = optional(list(string), [])
    routes_to_tgw       = optional(list(string), [])

    # 이 어태치먼트에만 추가할 태그
    tags = optional(map(string), {})
  }))
  default = {}
}

# ─────────────────────────────────────────
# Route Tables
# ─────────────────────────────────────────
variable "tgw_route_tables" {
  description = "TGW 라우트 테이블 정의. 키 이름이 vpc_attachments.route_table_key와 매핑됩니다."
  type = map(object({
    # 실제 AWS 리소스 이름에 붙는 suffix. 최종 이름은 '<project>-<env>-<name>' 형태
    name = string
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tgw_route_table_propagations" {
  description = "라우트 전파 설정. 'attachment_key VPC의 CIDR을 route_table_key 테이블에 전파'를 의미합니다."
  type = map(object({
    route_table_key = string # 전파 대상 라우트 테이블 (tgw_route_tables의 키)
    attachment_key  = string # 경로를 제공하는 VPC 어태치먼트 (vpc_attachments의 키)
  }))
  default = {}
  # 읽는 법: { route_table_key = "A", attachment_key = "B" }
  #   → B VPC의 CIDR을 A 라우트 테이블에 전파
  #   → A 라우트 테이블을 가진 VPC에서 B VPC로 패킷을 보낼 수 있게 됨
}

variable "tgw_static_routes" {
  description = "TGW 정적 경로. 전파로 자동 학습되지 않거나 명시적 차단(블랙홀)이 필요한 경로에 사용."
  type = map(object({
    route_table_key        = string           # 경로를 추가할 라우트 테이블 (tgw_route_tables의 키)
    destination_cidr_block = string           # 대상 CIDR (예: "0.0.0.0/0", "10.20.0.0/16")
    attachment_key         = optional(string) # 트래픽을 보낼 어태치먼트. blackhole=true이면 생략
    blackhole              = optional(bool, false) # true: 해당 CIDR로 오는 패킷을 버림 (명시적 차단)
  }))
  default = {}
}

# ─────────────────────────────────────────
# RAM (Resource Access Manager) - 멀티 어카운트
# ─────────────────────────────────────────
variable "enable_ram_sharing" {
  description = "AWS RAM으로 다른 계정에 TGW를 공유할지 여부. 단일 계정이면 false."
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "TGW를 공유할 대상. AWS 계정 ID(12자리) 또는 Organization OU ARN을 입력."
  type        = list(string)
  default     = []
  # 예시: ["123456789012", "arn:aws:organizations::111122223333:ou/o-xxxx/ou-xxxx-xxxxxxxx"]
  # enable_ram_sharing = true 일 때만 사용됩니다.
}

variable "ram_allow_external_principals" {
  description = "같은 Organization 외부의 계정과도 공유할지 여부. 일반적으로 false."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────
# VPN Connection
# ─────────────────────────────────────────
variable "vpn_connections" {
  description = "TGW에 연결할 Site-to-Site VPN 목록. 온프레미스 연동이 필요한 경우에만 설정."
  type = map(object({
    # [필수] 사전에 생성한 Customer Gateway ID (cgw-로 시작)
    # Customer Gateway는 온프레미스 VPN 장비의 공인 IP와 ASN으로 먼저 생성해야 합니다.
    # aws ec2 create-customer-gateway --type ipsec.1 --public-ip <온프레미스 공인IP> --bgp-asn <ASN>
    customer_gateway_id = string

    type               = optional(string, "ipsec.1") # 현재 AWS는 ipsec.1만 지원
    route_table_key    = optional(string)             # VPN 어태치먼트를 연결할 TGW 라우트 테이블 키
    static_routes_only = optional(bool, false)        # false: BGP 동적 라우팅 (권장) / true: 정적 경로만

    # PSK(Pre-Shared Key): null이면 AWS가 자동 생성 (권장)
    # 직접 지정할 경우 8~64자, 영문/숫자만 가능
    tunnel1_psk = optional(string) # [보안] Secrets Manager 또는 Vault에서 참조 권장
    tunnel2_psk = optional(string)

    # 터널 내부 IP (/30 CIDR). null이면 AWS가 169.254.x.x 대역에서 자동 할당
    # 온프레미스 장비가 특정 IP를 요구하는 경우에만 지정
    tunnel1_inside_cidr = optional(string) # 예: "169.254.10.0/30"
    tunnel2_inside_cidr = optional(string) # 예: "169.254.11.0/30"

    # DPD(Dead Peer Detection) 타임아웃 동작
    # restart: 터널 자동 재연결 (권장) / clear: 터널 종료 / none: 아무것도 안 함
    tunnel1_dpd_timeout_action = optional(string, "restart")
    tunnel2_dpd_timeout_action = optional(string, "restart")

    # IKE 버전. ikev2 권장 (보안성, 성능 우수)
    tunnel1_ike_versions = optional(list(string), ["ikev2"])
    tunnel2_ike_versions = optional(list(string), ["ikev2"])

    tags = optional(map(string), {})
  }))
  default = {}
}

# ─────────────────────────────────────────
# Tags
# ─────────────────────────────────────────
variable "tags" {
  description = "모든 리소스에 추가할 공통 태그. versions.tf의 default_tags와 합산됩니다."
  type        = map(string)
  default     = {}
  # 조직의 태깅 정책(CostCenter, Owner, Team 등)에 맞게 설정하세요.
}

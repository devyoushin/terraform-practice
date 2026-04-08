variable "name" {
  description = "VPN 연결 이름"
  type        = string
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "customer_gateway_id" {
  description = "고객 게이트웨이 ID"
  type        = string
}

variable "type" {
  description = "VPN 연결 유형"
  type        = string
  default     = "ipsec.1"
}

variable "static_routes_only" {
  description = "정적 경로만 사용 여부 (false이면 BGP 동적 라우팅)"
  type        = bool
  default     = false
}

variable "tunnel1_psk" {
  description = "터널1 사전 공유 키 (null이면 AWS 자동 생성)"
  type        = string
  default     = null
  sensitive   = true
}

variable "tunnel2_psk" {
  description = "터널2 사전 공유 키 (null이면 AWS 자동 생성)"
  type        = string
  default     = null
  sensitive   = true
}

variable "tunnel1_inside_cidr" {
  description = "터널1 내부 IP CIDR (/30)"
  type        = string
  default     = null
}

variable "tunnel2_inside_cidr" {
  description = "터널2 내부 IP CIDR (/30)"
  type        = string
  default     = null
}

variable "tunnel1_dpd_timeout_action" {
  description = "터널1 DPD 타임아웃 동작 (restart | clear | none)"
  type        = string
  default     = "restart"
}

variable "tunnel2_dpd_timeout_action" {
  description = "터널2 DPD 타임아웃 동작 (restart | clear | none)"
  type        = string
  default     = "restart"
}

variable "tunnel1_ike_versions" {
  description = "터널1 IKE 버전 목록"
  type        = list(string)
  default     = ["ikev2"]
}

variable "tunnel2_ike_versions" {
  description = "터널2 IKE 버전 목록"
  type        = list(string)
  default     = ["ikev2"]
}

variable "transit_gateway_route_table_id" {
  description = "어태치먼트를 연결할 TGW 라우트 테이블 ID"
  type        = string
  default     = null
}

variable "enable_tunnel_logging" {
  description = "CloudWatch 터널 로깅 활성화 여부"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (일)"
  type        = number
  default     = 90
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}

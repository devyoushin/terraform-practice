variable "name" {
  description = "Transit Gateway 이름"
  type        = string
}

variable "description" {
  description = "Transit Gateway 설명"
  type        = string
  default     = ""
}

variable "amazon_side_asn" {
  description = "Amazon 측 BGP ASN"
  type        = number
  default     = 64512
}

variable "auto_accept_shared_attachments" {
  description = "공유된 어태치먼트 자동 수락 여부"
  type        = bool
  default     = false
}

variable "default_route_table_association" {
  description = "기본 라우트 테이블 자동 연결 여부"
  type        = bool
  default     = false
}

variable "default_route_table_propagation" {
  description = "기본 라우트 테이블 자동 전파 여부"
  type        = bool
  default     = false
}

variable "dns_support" {
  description = "DNS 지원 여부"
  type        = bool
  default     = true
}

variable "vpn_ecmp_support" {
  description = "VPN ECMP 지원 여부"
  type        = bool
  default     = true
}

variable "multicast_support" {
  description = "멀티캐스트 지원 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}

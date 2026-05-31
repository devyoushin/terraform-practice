variable "name" {
  description = "어태치먼트 이름"
  type        = string
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "vpc_id" {
  description = "연결할 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "어태치먼트에 사용할 서브넷 ID 목록 (가용영역당 1개, TGW 전용 서브넷 권장)"
  type        = list(string)
}

variable "transit_gateway_default_route_table_association" {
  description = "기본 TGW 라우트 테이블과 자동 연결 여부"
  type        = bool
  default     = false
}

variable "transit_gateway_default_route_table_propagation" {
  description = "기본 TGW 라우트 테이블에 자동 전파 여부"
  type        = bool
  default     = false
}

variable "appliance_mode_support" {
  description = "어플라이언스 모드 활성화 여부 (방화벽/NVA 배포 시 사용)"
  type        = bool
  default     = false
}

variable "dns_support" {
  description = "DNS 지원 여부"
  type        = bool
  default     = true
}

variable "ipv6_support" {
  description = "IPv6 지원 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}

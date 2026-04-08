variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "name" {
  description = "라우트 테이블 이름"
  type        = string
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}

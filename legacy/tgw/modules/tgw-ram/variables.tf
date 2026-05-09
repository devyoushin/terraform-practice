variable "name" {
  description = "RAM 리소스 공유 이름"
  type        = string
}

variable "transit_gateway_arn" {
  description = "공유할 Transit Gateway ARN"
  type        = string
}

variable "principals" {
  description = "TGW를 공유할 AWS 계정 ID 또는 OU ARN 목록"
  type        = list(string)
}

variable "allow_external_principals" {
  description = "외부 AWS Organization과의 공유 허용 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}

###
### dev 환경 - 변수 정의
###

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "프로젝트명. 리소스 이름 접두어로 사용됩니다."
  type        = string
  default     = "mycompany"
}

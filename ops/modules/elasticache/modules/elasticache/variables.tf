### =============================================================================
### modules/elasticache/variables.tf
### AWS ElastiCache Redis 모듈 입력 변수 정의
### =============================================================================

variable "project_name" {
  description = "프로젝트 이름. 리소스 이름 prefix로 사용됩니다."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.project_name))
    error_message = "project_name은 소문자, 숫자, 하이픈만 사용 가능합니다."
  }
}

variable "environment" {
  description = "배포 환경."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment는 dev, prod 중 하나여야 합니다."
  }
}

variable "vpc_id" {
  description = "Redis 보안 그룹을 생성할 VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Redis 클러스터를 배치할 프라이빗 서브넷 ID 목록. (최소 2개, 서로 다른 가용영역)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Redis 포트(6379)에 접근을 허용할 CIDR 블록 목록. VPC CIDR 입력 권장."
  type        = list(string)
}

variable "node_type" {
  description = "Redis 노드 인스턴스 타입. dev: cache.t3.micro, prod: cache.r7g.large 권장."
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_version" {
  description = "Redis 엔진 버전. (예: '7.1', '7.0', '6.2')"
  type        = string
  default     = "7.1"
}

variable "num_cache_clusters" {
  description = "전체 노드 수 (Primary 포함). 1=Primary만(dev), 2=Primary+Replica(prod 권장)."
  type        = number
  default     = 1
  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "num_cache_clusters는 1 이상 6 이하여야 합니다."
  }
}

variable "multi_az_enabled" {
  description = "Multi-AZ 활성화 여부. num_cache_clusters > 1일 때만 유효. prod 환경에서 true 권장."
  type        = bool
  default     = false
}

variable "maxmemory_policy" {
  description = "메모리 한계 도달 시 키 제거 방식. allkeys-lru(기본), volatile-lru, noeviction 등."
  type        = string
  default     = "allkeys-lru"
}

variable "auth_token" {
  description = "Redis AUTH 토큰. transit_encryption_enabled = true일 때만 설정 가능. null이면 미사용."
  type        = string
  default     = null
  sensitive   = true
}

variable "apply_immediately" {
  description = "변경 사항 즉시 적용 여부. dev: true, staging/prod: false (유지보수 시간에 적용)."
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "스냅샷 보존 일수. 0이면 스냅샷 비활성화. dev: 0, staging: 1, prod: 7 권장."
  type        = number
  default     = 0
}

variable "snapshot_window" {
  description = "스냅샷 생성 시간대 (UTC). 예: '03:00-04:00'"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "유지보수 시간대 (UTC). 예: 'mon:04:00-mon:05:00'"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "enable_logs" {
  description = "CloudWatch 로그 활성화 여부. true로 설정하면 slow-log와 engine-log를 CloudWatch로 전송. prod 권장."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그 맵."
  type        = map(string)
  default     = {}
}

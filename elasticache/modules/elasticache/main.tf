### ============================================================
### modules/elasticache/main.tf
### AWS ElastiCache Redis 복제 그룹 모듈
### Cluster Mode Disabled (단일 샤드, 복제 그룹) 구성 지원
### ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

### ============================================================
### 로컬 변수
### ============================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Redis 버전(예: "7.1") → 파라미터 그룹 family(예: "redis7") 변환
  redis_major_version = split(".", var.redis_version)[0]
  parameter_group_family = "redis${local.redis_major_version}"

  # CloudWatch 로그 그룹 이름
  slow_log_group_name   = "/elasticache/${local.name_prefix}/slow-log"
  engine_log_group_name = "/elasticache/${local.name_prefix}/engine-log"

  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "elasticache"
  })
}

### ============================================================
### 1. ElastiCache 서브넷 그룹
### 프라이빗 서브넷에 Redis 클러스터를 배치하기 위한 서브넷 그룹
### ============================================================

resource "aws_elasticache_subnet_group" "this" {
  name        = "${local.name_prefix}-redis-subnet-group"
  description = "${var.project_name} ${var.environment} Redis Subnet Group"
  subnet_ids  = var.subnet_ids # 프라이빗 서브넷 ID 목록

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-subnet-group"
  })
}

### ============================================================
### 2. ElastiCache 파라미터 그룹
### Redis 엔진 설정 파라미터를 정의
### ============================================================

resource "aws_elasticache_parameter_group" "this" {
  name        = "${local.name_prefix}-redis-param-group"
  description = "${var.project_name} ${var.environment} Redis Parameter Group"
  family      = local.parameter_group_family # redis7 등

  # 메모리 정책: 메모리 한계 도달 시 키 제거 방식
  # allkeys-lru (기본) / volatile-lru / noeviction 등
  parameter {
    name  = "maxmemory-policy"
    value = var.maxmemory_policy
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-param-group"
  })

  lifecycle {
    # 파라미터 그룹 이름 변경 시 기존 것을 먼저 삭제하지 않도록
    create_before_destroy = true
  }
}

### ============================================================
### 3. 보안 그룹
### Redis 포트(6379)에 대한 인바운드 접근 제어
### ============================================================

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for ${var.project_name} ${var.environment} Redis"
  vpc_id      = var.vpc_id

  ### 인바운드: 허용된 CIDR 블록에서 Redis 포트(6379)만 허용
  ingress {
    description = "Redis port from allowed CIDR blocks"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ### 아웃바운드: 전체 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

### ============================================================
### 4. CloudWatch 로그 그룹 (enable_logs = true일 때만 생성)
### slow-log: 느린 쿼리 로그
### engine-log: Redis 엔진 로그
### ============================================================

resource "aws_cloudwatch_log_group" "slow_log" {
  count = var.enable_logs ? 1 : 0

  name              = local.slow_log_group_name
  retention_in_days = 30 # 로그 보존 기간 (30일)

  tags = merge(local.common_tags, {
    Name    = local.slow_log_group_name
    LogType = "slow-log"
  })
}

resource "aws_cloudwatch_log_group" "engine_log" {
  count = var.enable_logs ? 1 : 0

  name              = local.engine_log_group_name
  retention_in_days = 30 # 로그 보존 기간 (30일)

  tags = merge(local.common_tags, {
    Name    = local.engine_log_group_name
    LogType = "engine-log"
  })
}

### ============================================================
### 5. ElastiCache 복제 그룹 (Replication Group)
### Cluster Mode Disabled: 단일 샤드, Primary + Replica 구성
### num_cache_clusters = 1 → Primary만 (dev)
### num_cache_clusters = 2 → Primary + Replica 1개 (prod)
### ============================================================

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "${var.project_name} ${var.environment} Redis"

  ### 노드 설정
  node_type          = var.node_type           # 예: cache.t3.micro, cache.r7g.large
  num_cache_clusters = var.num_cache_clusters  # 전체 노드 수 (Primary 포함)
  port               = 6379

  ### 고가용성 설정
  # num_cache_clusters > 1 (복제본 존재) 시 자동 failover 활성화
  automatic_failover_enabled = var.num_cache_clusters > 1
  multi_az_enabled           = var.multi_az_enabled

  ### Redis 엔진 설정
  engine_version       = var.redis_version
  parameter_group_name = aws_elasticache_parameter_group.this.name

  ### 네트워크 설정
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  ### 보안 설정 (항상 암호화 활성화)
  at_rest_encryption_enabled  = true # 저장 데이터 암호화 (항상 활성화)
  transit_encryption_enabled  = true # 전송 중 암호화 / TLS (항상 활성화)

  # Redis AUTH 토큰 - transit_encryption_enabled = true 일 때만 설정 가능
  # null이면 auth_token 블록 자체를 생략 (토큰 미사용)
  auth_token = var.auth_token

  ### 유지 관리 설정
  apply_immediately = var.apply_immediately # dev: true, staging/prod: false

  ### 스냅샷 설정
  # dev: 0 (비활성화), staging: 1일, prod: 7일
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window          # "03:00-04:00"
  maintenance_window       = var.maintenance_window       # "Mon:04:00-Mon:05:00"

  ### CloudWatch 로그 전송 설정 (enable_logs = true일 때만 활성화)
  # slow-log: 실행 시간이 임계값을 초과한 쿼리 기록
  dynamic "log_delivery_configuration" {
    for_each = var.enable_logs ? [1] : []
    content {
      destination      = aws_cloudwatch_log_group.slow_log[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
  }

  # engine-log: Redis 엔진 자체 이벤트/오류 로그
  dynamic "log_delivery_configuration" {
    for_each = var.enable_logs ? [1] : []
    content {
      destination      = aws_cloudwatch_log_group.engine_log[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis"
  })

  lifecycle {
    # auth_token은 최초 설정 이후 Terraform 상태에서 변경 감지 방지
    ignore_changes = [auth_token]
  }

  # 로그 그룹이 먼저 생성되어야 함
  depends_on = [
    aws_cloudwatch_log_group.slow_log,
    aws_cloudwatch_log_group.engine_log,
  ]
}

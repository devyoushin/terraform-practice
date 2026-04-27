### =============================================================================
### dev/elasticache/terragrunt.hcl
### DEV 환경 ElastiCache (Redis)
###
### 역할: 세션 캐시, 인증 토큰, 빈번히 조회되는 데이터 캐싱
###       RDS 부하 감소 및 응답 속도 향상
### DEV 특징:
###   - cache.t3.micro: 최소 사양 (비용 절약)
###   - num_node_groups = 1, replicas_per_node_group = 0: 단일 노드
###   - multi_az_enabled = false: 단일 AZ
###   - automatic_failover_enabled = false: 자동 장애조치 비활성화
###   - snapshot_retention_limit = 0: 스냅샷 비활성화
###   - apply_immediately = true: 변경사항 즉시 적용
### 의존성: vpc
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-11111111111111111", "subnet-11111111111111112"]
    vpc_cidr_block     = "10.10.0.0/16"
  }
}

terraform {
  source = "../../elasticache/modules/elasticache"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # ElastiCache는 프라이빗 서브넷에 배포 (외부 접근 차단)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # 허용 CIDR (VPC 내부에서만 접근)
  allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]

  # ---------------------------------------------------------------
  # 노드 사양
  # dev: cache.t3.micro (최소 비용)
  # prod: cache.r6g.large 이상 (실제 캐시 워크로드)
  # ---------------------------------------------------------------
  node_type = "cache.t3.micro"

  # ---------------------------------------------------------------
  # 클러스터 구성 (Redis Cluster 모드)
  # dev: 단일 샤드, 복제본 없음 (비용 최소화)
  # prod: 여러 샤드 + 복제본 (고가용성 + 읽기 분산)
  # ---------------------------------------------------------------
  num_node_groups          = 1
  replicas_per_node_group  = 0

  # ---------------------------------------------------------------
  # 고가용성 설정
  # dev: 비활성화 (단일 노드이므로 불필요)
  # prod: multi_az_enabled = true, automatic_failover_enabled = true
  # ---------------------------------------------------------------
  multi_az_enabled           = false
  automatic_failover_enabled = false

  # ---------------------------------------------------------------
  # 스냅샷 (백업)
  # dev: 0 = 스냅샷 비활성화 (캐시 데이터는 재생성 가능)
  # prod: 1~35일 보존 (장애 시 데이터 복구)
  # ---------------------------------------------------------------
  snapshot_retention_limit = 0

  # ---------------------------------------------------------------
  # 변경 적용 시점
  # dev: 즉시 (유지보수 창 무시)
  # prod: 유지보수 창에 적용 (서비스 중단 최소화)
  # ---------------------------------------------------------------
  apply_immediately = true

  # ---------------------------------------------------------------
  # Redis 버전
  # ---------------------------------------------------------------
  engine_version = "7.0"
}

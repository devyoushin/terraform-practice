### =============================================================================
### prod/elasticache/terragrunt.hcl
### PROD 환경 ElastiCache — Redis 클러스터
###
### 역할: 세션 캐시, 분산 캐시, 실시간 리더보드 등
### PROD 특징:
###   - node_type = "cache.r7g.large"         (dev: cache.t3.micro)
###   - multi_az_enabled = true                (다중 AZ 고가용성)
###   - automatic_failover_enabled = true      (자동 장애 조치)
###   - replicas_per_node_group = 1            (읽기 복제본 1개)
###   - snapshot_retention_limit = 7           (스냅샷 7일 보존)
###   - enable_cloudwatch_logs = true          (CloudWatch 로그 수집)
###   - KMS 암호화 (저장/전송 암호화)
###
### 의존성:
###   - vpc     → 프라이빗 서브넷 ID
###   - kms/s3  → 암호화 KMS 키
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ node_type 변경은 클러스터 재시작 발생 가능 — 유지보수 창 활용
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_cidr_block     = "10.0.0.0/16"
  }
}

dependency "kms_s3" {
  config_path = "../kms/s3"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_id  = "00000000-0000-0000-0000-000000000000"
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

terraform {
  source = "../../elasticache/modules/elasticache"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 배치
  # 프라이빗 서브넷에만 배치 (캐시 서버는 외부 노출 불필요)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # ---------------------------------------------------------------
  # Redis 버전
  # ---------------------------------------------------------------
  redis_version = "7.0"

  # ---------------------------------------------------------------
  # 노드 타입 (인스턴스 크기)
  # prod: cache.r7g.large — 메모리 최적화 인스턴스 (대용량 캐시)
  # dev:  cache.t3.micro  — 비용 최소화
  #
  # 메모리 용량:
  #   cache.t3.micro  → 0.555 GB
  #   cache.r7g.large → 13.07 GB
  # ---------------------------------------------------------------
  node_type = "cache.r7g.large"

  # ---------------------------------------------------------------
  # 클러스터 구성 (클러스터 모드 비활성화 — 단일 샤드)
  # num_node_groups: 샤드(shard) 수 — 1로 설정 (단일 샤드)
  # replicas_per_node_group: 샤드당 읽기 복제본 수 — 1개
  #
  # 구성: Primary 1개 + Replica 1개 = 총 2개 노드
  # ---------------------------------------------------------------
  num_node_groups          = 1
  replicas_per_node_group  = 1

  # ---------------------------------------------------------------
  # 고가용성 설정
  # prod: Multi-AZ + 자동 장애 조치 활성화
  #   → Primary 장애 시 Replica가 자동으로 Primary로 승격 (수십 초)
  # dev:  false (단일 노드 — 비용 절약)
  # ---------------------------------------------------------------
  multi_az_enabled             = true
  automatic_failover_enabled   = true

  # ---------------------------------------------------------------
  # 스냅샷 (백업)
  # prod: 7일 보존 — 데이터 복구 옵션 확보
  # dev:  0 (스냅샷 비활성화)
  #
  # 스냅샷 윈도우: 트래픽이 적은 새벽 시간
  # ---------------------------------------------------------------
  snapshot_retention_limit = 7
  snapshot_window          = "04:00-05:00"  # UTC (한국 오전 1-2시)

  # ---------------------------------------------------------------
  # 암호화
  # prod: KMS CMK로 저장 및 전송 데이터 암호화
  # ---------------------------------------------------------------
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  kms_key_id                  = dependency.kms_s3.outputs.key_id

  # ---------------------------------------------------------------
  # 접근 제어
  # VPC CIDR 내부 접근만 허용
  # ---------------------------------------------------------------
  allowed_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]

  # ---------------------------------------------------------------
  # CloudWatch 로그
  # prod: 활성화 — Slow Log 및 Engine Log 수집
  # ---------------------------------------------------------------
  enable_cloudwatch_logs = true
}

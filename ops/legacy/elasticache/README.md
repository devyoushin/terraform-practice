# terraform-elasticache

재사용 가능한 AWS ElastiCache Redis Terraform 모듈입니다.
Cluster Mode Disabled(단일 샤드, Primary + Replica) 구성으로 고가용성 Redis를 제공합니다.

## 아키텍처

```
[dev 환경]                    [prod 환경]
Primary Node                  Primary Node
(cache.t3.micro)              (cache.r7g.large)
                                    │ 자동 Failover
                              Replica Node
                              (Multi-AZ)
```

**항상 활성화되는 보안 설정:**
- `at_rest_encryption_enabled = true` (저장 데이터 암호화)
- `transit_encryption_enabled = true` (전송 중 암호화 / TLS)

## 모듈 구조

```
terraform-elasticache/
├── modules/
│   └── elasticache/
│       ├── main.tf        # 복제 그룹, 서브넷 그룹, 파라미터 그룹, 보안 그룹, CloudWatch 로그
│       ├── variables.tf   # 입력 변수 정의
│       └── outputs.tf     # 출력값 (엔드포인트, 보안 그룹 ID 등)
│
├── envs/
│   ├── dev/               # 개발 환경 (1 노드, 스냅샷 없음)
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 운영 환경 (Multi-AZ, 스냅샷, 로그 활성화)
│
├── terraform.tfvars.example
└── README.md
```

## 모듈 입력 변수

| 변수 | 설명 | 필수 | 기본값 |
|------|------|------|--------|
| `project_name` | 프로젝트 이름 | ✅ | - |
| `environment` | 환경 (dev/staging/prod) | ✅ | - |
| `vpc_id` | VPC ID | ✅ | - |
| `subnet_ids` | 프라이빗 서브넷 ID 목록 | ✅ | - |
| `allowed_cidr_blocks` | Redis 접근 허용 CIDR 목록 | ✅ | - |
| `node_type` | 노드 인스턴스 타입 | ✅ | - |
| `redis_version` | Redis 버전 (예: "7.1") | ❌ | `"7.1"` |
| `num_cache_clusters` | 전체 노드 수 (Primary 포함) | ❌ | `1` |
| `multi_az_enabled` | Multi-AZ 활성화 | ❌ | `false` |
| `maxmemory_policy` | 메모리 한계 도달 시 키 제거 방식 | ❌ | `"allkeys-lru"` |
| `auth_token` | Redis AUTH 토큰 | ❌ | `null` |
| `apply_immediately` | 즉시 적용 (dev: true) | ❌ | `true` |
| `snapshot_retention_limit` | 스냅샷 보존 일수 (0=비활성) | ❌ | `0` |
| `snapshot_window` | 스냅샷 시간대 | ❌ | `"03:00-04:00"` |
| `maintenance_window` | 유지보수 시간대 | ❌ | `"mon:04:00-mon:05:00"` |
| `enable_logs` | CloudWatch 로그 활성화 | ❌ | `false` |
| `common_tags` | 공통 태그 | ❌ | `{}` |

## 모듈 출력값

| 출력 | 설명 |
|------|------|
| `primary_endpoint_address` | Primary 엔드포인트 (쓰기 연결) |
| `reader_endpoint_address` | Reader 엔드포인트 (읽기 연결) |
| `replication_group_id` | 복제 그룹 ID |
| `security_group_id` | Redis 보안 그룹 ID |
| `port` | Redis 포트 (6379) |

## 사용 방법

### 1. 환경 디렉토리로 이동

```bash
cd envs/dev   # 또는 envs/staging, envs/prod
```

### 2. 변수 파일 복사 및 편집

```bash
cp ../../terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집하여 실제 값 입력
```

### 3. 초기화 및 배포

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. 연결 테스트

```bash
# Bastion 또는 앱 서버에서
redis-cli -h $(terraform output -raw primary_endpoint_address) -p 6379
```

## 환경별 권장 설정

| 설정 | dev | staging | prod |
|------|-----|---------|------|
| `node_type` | cache.t3.micro | cache.t3.small | cache.r7g.large |
| `num_cache_clusters` | 1 | 1 | 2 |
| `multi_az_enabled` | false | false | true |
| `snapshot_retention_limit` | 0 | 1 | 7 |
| `enable_logs` | false | false | true |
| `apply_immediately` | true | false | false |

## 요구 사항

| 도구 | 버전 |
|------|------|
| Terraform | >= 1.5.0 |
| AWS Provider | >= 5.0 |

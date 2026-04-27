### =============================================================================
### dev/eks/terragrunt.hcl
### DEV 환경 EKS (Elastic Kubernetes Service)
###
### 역할: 컨테이너 워크로드를 실행하는 Kubernetes 클러스터
### DEV 특징:
###   - 클러스터 이름: dev-eks
###   - 워커 노드: t3.medium (개발 테스트 용도)
###   - 단일 노드 그룹, 최소 1 / 최대 3 노드 (비용 절약)
###   - KMS Secrets 암호화: 선택적 (prod: 필수)
###   - Public Endpoint 활성화 (kubectl 직접 접근 허용)
### 배포 순서 주의:
###   EKS 클러스터 먼저 배포 → 이후 Karpenter/Add-on 설치
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
    public_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_cidr_block     = "10.10.0.0/16"
  }
}

terraform {
  source = "../../eks/modules/eks"
}

inputs = {
  # ---------------------------------------------------------------
  # 클러스터 식별자
  # ---------------------------------------------------------------
  cluster_name = "dev-eks"

  # ---------------------------------------------------------------
  # Kubernetes 버전
  # 최신 안정 버전 사용 권장
  # 업그레이드: 마이너 버전을 한 단계씩 순차 업그레이드
  # ---------------------------------------------------------------
  cluster_version = "1.29"

  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # EKS 워커 노드는 프라이빗 서브넷에 배포
  # (인터넷 트래픽은 ALB/Ingress를 통해 수신)
  # ---------------------------------------------------------------
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # ---------------------------------------------------------------
  # API 서버 엔드포인트 접근 설정
  # dev: 퍼블릭 엔드포인트 활성화 (kubectl 직접 접근)
  # prod: 프라이빗 엔드포인트만 (Bastion/VPN 경유)
  # ---------------------------------------------------------------
  endpoint_public_access  = true
  endpoint_private_access = true

  # 퍼블릭 접근 허용 CIDR (dev: 전체, prod: 사무실 IP로 제한)
  public_access_cidrs = ["0.0.0.0/0"]

  # ---------------------------------------------------------------
  # 관리형 노드 그룹 설정
  # ---------------------------------------------------------------
  node_instance_types = ["t3.medium"]

  # 노드 수 설정
  node_desired_size = 2
  node_min_size     = 1
  node_max_size     = 3

  # 노드 디스크 크기 (GiB)
  node_disk_size = 20

  # ---------------------------------------------------------------
  # 클러스터 로깅
  # dev: 최소한의 로그 (비용 절약)
  # prod: 모든 로그 유형 활성화
  # ---------------------------------------------------------------
  cluster_enabled_log_types = ["api", "audit"]

  # ---------------------------------------------------------------
  # Add-on 설정
  # 필수 Add-on: vpc-cni, coredns, kube-proxy
  # ---------------------------------------------------------------
  enable_vpc_cni    = true
  enable_coredns    = true
  enable_kube_proxy = true
  enable_ebs_csi    = true
}

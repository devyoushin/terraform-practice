### =============================================================================
### prod/eks/terragrunt.hcl
### PROD 환경 EKS — Kubernetes 클러스터
###
### 역할: 컨테이너 워크로드를 위한 관리형 Kubernetes 클러스터
### PROD 특징:
###   - 3개 AZ에 걸친 워커 노드 배치 (고가용성)
###   - KMS Envelope Encryption (Kubernetes Secrets 암호화)
###   - 프라이빗 서브넷에만 워커 노드 배치 (보안)
###   - 로깅 전체 활성화 (감사 로그 포함)
###
### 배포 순서 (중요!):
###   1. kms/eks → 2. vpc → 3. eks → 4. Karpenter/add-ons
###
### 의존성:
###   - vpc     → 프라이빗 서브넷 ID (워커 노드 배치)
###   - kms/eks → Secrets 암호화 KMS 키
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ EKS 클러스터 삭제 시 모든 워크로드(Pod, Service 등) 삭제됨
### ⚠️ Karpenter 설치는 클러스터 생성 완료 후 별도 진행
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

dependency "kms_eks" {
  config_path = "../kms/eks"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_id  = "00000000-0000-0000-0000-000000000000"
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

terraform {
  source = "../../eks/modules/eks"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 클러스터 식별자
  # prod 클러스터명은 환경을 명시적으로 구분
  # ---------------------------------------------------------------
  cluster_name = "prod-eks"

  # ---------------------------------------------------------------
  # Kubernetes 버전
  # ⚠️ 버전 업그레이드는 반드시 EKS 업그레이드 절차를 따를 것
  #    (컨트롤 플레인 → 관리형 노드 그룹 순서)
  # ---------------------------------------------------------------
  cluster_version = "1.29"

  # ---------------------------------------------------------------
  # 네트워크 배치
  # 워커 노드: 프라이빗 서브넷 3개 AZ (외부 직접 노출 없음)
  # ALB Ingress Controller가 퍼블릭 서브넷에 ALB 생성 (자동)
  # ---------------------------------------------------------------
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # ---------------------------------------------------------------
  # API 서버 엔드포인트 접근 제어
  # prod: 프라이빗 엔드포인트 활성화 (VPC 내부에서 접근)
  #       퍼블릭 엔드포인트는 제한적 IP만 허용 (Bastion/VPN IP)
  # ---------------------------------------------------------------
  endpoint_private_access = true
  endpoint_public_access  = true  # Bastion 없는 환경에서는 true 유지
  # public_access_cidrs   = ["REPLACE_WITH_YOUR_OFFICE_OR_VPN_CIDR"]

  # ---------------------------------------------------------------
  # 클러스터 로깅
  # prod: 전체 로그 타입 활성화 (보안 감사 및 장애 분석)
  #   - api: API 서버 요청
  #   - audit: 감사 로그 (보안 필수)
  #   - authenticator: 인증 로그
  #   - controllerManager: 컨트롤러 로그
  #   - scheduler: 스케줄러 로그
  # ---------------------------------------------------------------
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  # ---------------------------------------------------------------
  # KMS Envelope Encryption
  # prod: Kubernetes Secrets를 etcd 저장 전 CMK로 암호화
  # ---------------------------------------------------------------
  enable_secrets_encryption = true
  kms_key_arn               = dependency.kms_eks.outputs.key_arn

  # ---------------------------------------------------------------
  # 관리형 노드 그룹 (Managed Node Group)
  # 기본 시스템 컴포넌트(CoreDNS, kube-proxy 등)용 노드
  # 애플리케이션 워크로드는 Karpenter로 동적 관리
  # ---------------------------------------------------------------
  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 50
      labels = {
        role = "system"
      }
    }
  }

  # ---------------------------------------------------------------
  # 클러스터 애드온
  # ---------------------------------------------------------------
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

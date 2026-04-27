### =============================================================================
### prod/kms/eks/terragrunt.hcl
### PROD 환경 KMS 키 — EKS 시크릿 암호화용
###
### 역할: EKS 클러스터 내 Kubernetes Secrets(etcd 저장 데이터)
###       암호화에 사용할 KMS CMK 생성
###
### EKS envelope encryption:
###   - Kubernetes Secrets → KMS 키로 암호화 후 etcd 저장
###   - 클러스터 내 민감 정보(DB 패스워드, API 키 등) 보호
###   - AWS EKS 공식 권고 사항 (Envelope Encryption)
###
### PROD 특징:
###   - deletion_window_in_days = 30 (dev: 7일)
###   - enable_key_rotation = true (보안 컴플라이언스)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ EKS 클러스터 생성 전 이 키를 먼저 배포해야 합니다!
###    (EKS 모듈이 kms/eks에 의존)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../kms/modules/kms"
}

prevent_destroy = true  # Terragrunt: run-all destroy 실행 차단

inputs = {
  # ---------------------------------------------------------------
  # 키 식별자
  # 생성되는 별칭: alias/{project_name}-prod-eks
  # EKS 클러스터 생성 시 encryption_config 블록에서 이 키 ARN 참조
  # ---------------------------------------------------------------
  key_suffix = "eks"

  # ---------------------------------------------------------------
  # 키 삭제 대기 기간
  # prod: 30일 — EKS Secrets 복호화 불가 사태 방지
  # dev:  7일  — 개발 환경 신속 정리
  #
  # ⚠️ 이 키 삭제 시 EKS 클러스터 내 암호화된 모든 Secrets를
  #    복호화할 수 없게 됩니다 → 클러스터 운영 불가 상태 발생 가능
  # ---------------------------------------------------------------
  deletion_window_in_days = 30

  # ---------------------------------------------------------------
  # 키 교체 (Key Rotation)
  # prod: true — 연간 자동 교체
  # EKS Secrets 암호화 키도 정기 교체가 보안 모범 사례
  # ---------------------------------------------------------------
  enable_key_rotation = true
}

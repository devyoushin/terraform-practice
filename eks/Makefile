###############################################
# Makefile - terraform-eks 배포 자동화
# 사용법: make <target> ENV=<dev|staging|prod>
# 예시:   make plan ENV=dev
#
# !! 최초 배포 시 2단계 필수 !!
#   make init ENV=dev
#   make apply-vpc-eks ENV=dev   ← 1단계: VPC + EKS 먼저
#   make apply ENV=dev           ← 2단계: Karpenter 포함 전체
###############################################

ENV ?= dev
DIR = envs/$(ENV)

.PHONY: init plan apply apply-vpc-eks destroy fmt validate output check kubeconfig

init:
	cd $(DIR) && terraform init

plan:
	cd $(DIR) && terraform plan -out=tfplan

## 1단계: VPC + EKS 먼저 생성 (Karpenter 의존성 때문)
apply-vpc-eks:
	cd $(DIR) && terraform apply -target=module.vpc -target=module.eks -auto-approve

## 2단계: Karpenter 포함 전체 적용
apply:
	cd $(DIR) && terraform apply tfplan

apply-auto:
	cd $(DIR) && terraform apply -auto-approve

## 리소스 삭제 (Karpenter NodePool 먼저 삭제 필요)
destroy:
	@echo "⚠️  삭제 전 아래 명령어를 먼저 실행하세요:"
	@echo "   kubectl delete nodepool --all"
	@echo "   kubectl delete ec2nodeclass --all"
	@read -p "계속하려면 Enter를 누르세요..." _
	cd $(DIR) && terraform destroy

fmt:
	terraform fmt -recursive

validate:
	cd $(DIR) && terraform validate

output:
	cd $(DIR) && terraform output

## kubeconfig 업데이트
kubeconfig:
	aws eks update-kubeconfig --region ap-northeast-2 --name $(ENV)-eks

check: fmt validate
	@echo "✅ 포맷 및 유효성 검사 완료"

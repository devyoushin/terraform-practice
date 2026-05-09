###############################################
# Makefile - terraform-vpc 배포 자동화
# 사용법: make <target> ENV=<dev|staging|prod>
# 예시:   make plan ENV=dev
###############################################

ENV ?= dev
DIR = envs/$(ENV)

.PHONY: init plan apply destroy fmt validate

## 초기화
init:
	cd $(DIR) && terraform init

## 플랜 (변경 사항 미리 보기)
plan:
	cd $(DIR) && terraform plan -out=tfplan

## 적용
apply:
	cd $(DIR) && terraform apply tfplan

## 플랜 + 즉시 적용 (CI/CD용)
apply-auto:
	cd $(DIR) && terraform apply -auto-approve

## 리소스 삭제
destroy:
	cd $(DIR) && terraform destroy

## 코드 포맷
fmt:
	terraform fmt -recursive

## 유효성 검사
validate:
	cd $(DIR) && terraform validate

## 출력값 확인
output:
	cd $(DIR) && terraform output

## 전체 검증 (fmt + validate)
check: fmt validate
	@echo "✅ 포맷 및 유효성 검사 완료"

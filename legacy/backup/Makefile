###############################################
# Makefile - terraform-backup 배포 자동화
# 사용법: make <target> ENV=<dev|staging|prod>
# 예시:   make plan ENV=dev
###############################################

ENV ?= dev
DIR = envs/$(ENV)

.PHONY: init plan apply destroy fmt validate output check

init:
	cd $(DIR) && terraform init

plan:
	cd $(DIR) && terraform plan -out=tfplan

apply:
	cd $(DIR) && terraform apply tfplan

apply-auto:
	cd $(DIR) && terraform apply -auto-approve

destroy:
	cd $(DIR) && terraform destroy

fmt:
	terraform fmt -recursive

validate:
	cd $(DIR) && terraform validate

output:
	cd $(DIR) && terraform output

check: fmt validate
	@echo "✅ 포맷 및 유효성 검사 완료"

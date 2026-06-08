###
### Makefile - Terraform 환경별 명령어 단축키
### 사용법: make <target>
### 예시:   make plan-dev / make apply-prod
###

SHELL := /bin/bash

### ============================================================
### 환경 디렉토리 경로
### ============================================================

DEV_DIR     := envs/dev
STAGING_DIR := envs/staging
PROD_DIR    := envs/prod

### ============================================================
### 기본 타겟
### ============================================================

.PHONY: help
help: ## 사용 가능한 명령어 목록 출력
	@echo ""
	@echo "terraform-alb Makefile 명령어"
	@echo "=================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

### ============================================================
### dev 환경
### ============================================================

.PHONY: init-dev
init-dev: ## [dev] terraform init
	@echo ">>> [dev] terraform init"
	terraform -chdir=$(DEV_DIR) init

.PHONY: fmt-dev
fmt-dev: ## [dev] terraform fmt (코드 포맷 정리)
	@echo ">>> [dev] terraform fmt"
	terraform -chdir=$(DEV_DIR) fmt -recursive

.PHONY: validate-dev
validate-dev: ## [dev] terraform validate
	@echo ">>> [dev] terraform validate"
	terraform -chdir=$(DEV_DIR) validate

.PHONY: plan-dev
plan-dev: ## [dev] terraform plan
	@echo ">>> [dev] terraform plan"
	terraform -chdir=$(DEV_DIR) plan

.PHONY: apply-dev
apply-dev: ## [dev] terraform apply (자동 승인 없음)
	@echo ">>> [dev] terraform apply"
	terraform -chdir=$(DEV_DIR) apply

.PHONY: apply-dev-auto
apply-dev-auto: ## [dev] terraform apply -auto-approve (주의: 자동 승인)
	@echo ">>> [dev] terraform apply -auto-approve"
	terraform -chdir=$(DEV_DIR) apply -auto-approve

.PHONY: destroy-dev
destroy-dev: ## [dev] terraform destroy (주의: 리소스 삭제)
	@echo ">>> [dev] terraform destroy"
	terraform -chdir=$(DEV_DIR) destroy

.PHONY: output-dev
output-dev: ## [dev] terraform output
	@echo ">>> [dev] terraform output"
	terraform -chdir=$(DEV_DIR) output

### ============================================================
### staging 환경
### ============================================================

.PHONY: init-staging
init-staging: ## [staging] terraform init
	@echo ">>> [staging] terraform init"
	terraform -chdir=$(STAGING_DIR) init

.PHONY: fmt-staging
fmt-staging: ## [staging] terraform fmt (코드 포맷 정리)
	@echo ">>> [staging] terraform fmt"
	terraform -chdir=$(STAGING_DIR) fmt -recursive

.PHONY: validate-staging
validate-staging: ## [staging] terraform validate
	@echo ">>> [staging] terraform validate"
	terraform -chdir=$(STAGING_DIR) validate

.PHONY: plan-staging
plan-staging: ## [staging] terraform plan
	@echo ">>> [staging] terraform plan"
	terraform -chdir=$(STAGING_DIR) plan

.PHONY: apply-staging
apply-staging: ## [staging] terraform apply (자동 승인 없음)
	@echo ">>> [staging] terraform apply"
	terraform -chdir=$(STAGING_DIR) apply

.PHONY: apply-staging-auto
apply-staging-auto: ## [staging] terraform apply -auto-approve (주의: 자동 승인)
	@echo ">>> [staging] terraform apply -auto-approve"
	terraform -chdir=$(STAGING_DIR) apply -auto-approve

.PHONY: destroy-staging
destroy-staging: ## [staging] terraform destroy (주의: 리소스 삭제)
	@echo ">>> [staging] terraform destroy"
	terraform -chdir=$(STAGING_DIR) destroy

.PHONY: output-staging
output-staging: ## [staging] terraform output
	@echo ">>> [staging] terraform output"
	terraform -chdir=$(STAGING_DIR) output

### ============================================================
### prod 환경 (주의: 운영 환경)
### ============================================================

.PHONY: init-prod
init-prod: ## [prod] terraform init
	@echo ">>> [prod] terraform init"
	terraform -chdir=$(PROD_DIR) init

.PHONY: fmt-prod
fmt-prod: ## [prod] terraform fmt (코드 포맷 정리)
	@echo ">>> [prod] terraform fmt"
	terraform -chdir=$(PROD_DIR) fmt -recursive

.PHONY: validate-prod
validate-prod: ## [prod] terraform validate
	@echo ">>> [prod] terraform validate"
	terraform -chdir=$(PROD_DIR) validate

.PHONY: plan-prod
plan-prod: ## [prod] terraform plan
	@echo ">>> [prod] terraform plan"
	terraform -chdir=$(PROD_DIR) plan

.PHONY: apply-prod
apply-prod: ## [prod] terraform apply (자동 승인 없음 - 운영 환경 주의)
	@echo ">>> [prod] terraform apply (운영 환경 - 변경사항을 꼭 확인하세요)"
	terraform -chdir=$(PROD_DIR) apply

.PHONY: destroy-prod
destroy-prod: ## [prod] terraform destroy (주의: 운영 리소스 삭제)
	@echo ">>> [prod] !! 운영 환경 삭제 !! 정말 삭제하시겠습니까?"
	@read -p "계속하려면 'yes'를 입력하세요: " confirm && [ "$$confirm" = "yes" ] || exit 1
	terraform -chdir=$(PROD_DIR) destroy

.PHONY: output-prod
output-prod: ## [prod] terraform output
	@echo ">>> [prod] terraform output"
	terraform -chdir=$(PROD_DIR) output

### ============================================================
### 공통 - 전체 환경 포맷/검증
### ============================================================

.PHONY: fmt
fmt: fmt-dev fmt-staging fmt-prod ## 전체 환경 terraform fmt 실행

.PHONY: validate
validate: validate-dev validate-staging validate-prod ## 전체 환경 terraform validate 실행

.PHONY: fmt-module
fmt-module: ## 모듈 코드 포맷 정리
	@echo ">>> [modules] terraform fmt"
	terraform fmt -recursive modules/

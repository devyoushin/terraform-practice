### =============================================================================
### Makefile
### Terraform 환경별 작업 자동화
###
### [사용 방법]
###   make init ENV=dev          # dev 환경 초기화
###   make plan ENV=staging      # staging 환경 플랜 확인
###   make apply ENV=prod        # prod 환경 적용 (확인 필요)
###   make apply-auto ENV=dev    # dev 환경 자동 적용 (확인 없음)
###   make destroy ENV=dev       # dev 환경 리소스 삭제
###   make fmt                   # 모든 tf 파일 포맷 정리
###   make validate ENV=dev      # dev 환경 유효성 검사
###   make output ENV=dev        # dev 환경 출력값 확인
###   make check ENV=dev         # dev 환경 fmt + validate 일괄 실행
### =============================================================================

### 기본 환경 (ENV 미지정 시 dev 사용)
ENV ?= dev

### 환경 디렉토리 경로
ENV_DIR := envs/$(ENV)

### 환경 디렉토리 유효성 검사
VALID_ENVS := dev staging prod
ifeq ($(filter $(ENV),$(VALID_ENVS)),)
$(error [ERROR] ENV=$(ENV) 는 유효하지 않습니다. 유효한 환경: $(VALID_ENVS))
endif

### 색상 코드 (출력 가독성 향상)
CYAN  := \033[0;36m
GREEN := \033[0;32m
YELLOW:= \033[0;33m
RED   := \033[0;31m
RESET := \033[0m

### =============================================================================
### 기본 타겟
### =============================================================================
.DEFAULT_GOAL := help

.PHONY: help init plan apply apply-auto destroy fmt validate output check

help: ## 사용 가능한 명령어 목록 출력
	@echo ""
	@echo "$(CYAN)=== Terraform SQS-SNS 관리 Makefile ===$(RESET)"
	@echo ""
	@echo "$(YELLOW)사용법:$(RESET) make <타겟> ENV=<환경>"
	@echo "$(YELLOW)환경:$(RESET)   dev | staging | prod (기본값: dev)"
	@echo ""
	@echo "$(YELLOW)타겟 목록:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo ""

### =============================================================================
### Terraform 핵심 명령어
### =============================================================================

init: ## Terraform 초기화 (모듈, 프로바이더, 백엔드 다운로드)
	@echo "$(CYAN)[$(ENV)] terraform init 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) init
	@echo "$(GREEN)[$(ENV)] 초기화 완료$(RESET)"

plan: ## 변경 사항 미리보기 (실제 적용 없음)
	@echo "$(CYAN)[$(ENV)] terraform plan 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) plan -out=tfplan
	@echo "$(GREEN)[$(ENV)] 플랜 완료 (tfplan 파일 생성됨)$(RESET)"

apply: ## 변경 사항 적용 (확인 필요)
	@echo "$(CYAN)[$(ENV)] terraform apply 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) apply tfplan
	@echo "$(GREEN)[$(ENV)] 적용 완료$(RESET)"

apply-auto: ## 변경 사항 자동 적용 (확인 없음 - dev 환경에서만 사용 권장)
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)[경고] prod 환경에서는 apply-auto를 사용할 수 없습니다. 'make apply ENV=prod'를 사용하세요.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)[$(ENV)] terraform apply -auto-approve 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) apply -auto-approve
	@echo "$(GREEN)[$(ENV)] 자동 적용 완료$(RESET)"

destroy: ## 리소스 삭제 (주의: 복구 불가)
	@echo "$(RED)[경고] $(ENV) 환경의 모든 SQS-SNS 리소스를 삭제합니다!$(RESET)"
	@read -p "계속하려면 'yes'를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "yes" ]; then \
		echo "$(YELLOW)삭제가 취소되었습니다.$(RESET)"; \
		exit 1; \
	fi
	@terraform -chdir=$(ENV_DIR) destroy
	@echo "$(GREEN)[$(ENV)] 리소스 삭제 완료$(RESET)"

### =============================================================================
### 코드 품질 관리
### =============================================================================

fmt: ## 모든 Terraform 파일 포맷 정리 (재귀적 적용)
	@echo "$(CYAN)terraform fmt 실행 중 (전체 디렉토리)...$(RESET)"
	@terraform fmt -recursive .
	@echo "$(GREEN)포맷 정리 완료$(RESET)"

validate: ## 특정 환경의 Terraform 설정 유효성 검사
	@echo "$(CYAN)[$(ENV)] terraform validate 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) validate
	@echo "$(GREEN)[$(ENV)] 유효성 검사 통과$(RESET)"

check: fmt validate ## fmt + validate 일괄 실행 (커밋 전 권장)
	@echo "$(GREEN)모든 검사 통과$(RESET)"

### =============================================================================
### 정보 조회
### =============================================================================

output: ## 특정 환경의 Terraform 출력값 확인
	@echo "$(CYAN)[$(ENV)] terraform output 실행 중...$(RESET)"
	@terraform -chdir=$(ENV_DIR) output

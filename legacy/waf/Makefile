### =============================================================================
### Makefile - Terraform WAF 관리
### =============================================================================

ENV ?= dev
ENV_DIR := envs/$(ENV)
VALID_ENVS := dev staging prod
ifeq ($(filter $(ENV),$(VALID_ENVS)),)
$(error [ERROR] ENV=$(ENV) 는 유효하지 않습니다. 유효한 환경: $(VALID_ENVS))
endif

CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
RESET  := \033[0m

.DEFAULT_GOAL := help
.PHONY: help init plan apply apply-auto destroy fmt validate output check

help:
	@echo ""; echo "$(CYAN)=== Terraform WAF 관리 Makefile ===$(RESET)"; echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2}'

init: ## Terraform 초기화
	@terraform -chdir=$(ENV_DIR) init && echo "$(GREEN)[$(ENV)] 초기화 완료$(RESET)"

plan: ## 변경 사항 미리보기
	@terraform -chdir=$(ENV_DIR) plan -out=tfplan && echo "$(GREEN)[$(ENV)] 플랜 완료$(RESET)"

apply: ## 변경 사항 적용
	@terraform -chdir=$(ENV_DIR) apply tfplan && echo "$(GREEN)[$(ENV)] 적용 완료$(RESET)"

apply-auto: ## 자동 적용 (dev/staging 전용)
	@if [ "$(ENV)" = "prod" ]; then echo "$(RED)[경고] prod 환경에서는 apply-auto 사용 불가$(RESET)"; exit 1; fi
	@terraform -chdir=$(ENV_DIR) apply -auto-approve

destroy: ## 리소스 삭제
	@echo "$(RED)[경고] $(ENV) 환경의 모든 WAF 리소스를 삭제합니다!$(RESET)"
	@read -p "계속하려면 'yes'를 입력하세요: " CONFIRM; \
	if [ "$$CONFIRM" != "yes" ]; then echo "$(YELLOW)취소됨$(RESET)"; exit 1; fi
	@terraform -chdir=$(ENV_DIR) destroy

fmt: ## 코드 포맷 정리
	@terraform fmt -recursive . && echo "$(GREEN)포맷 정리 완료$(RESET)"

validate: ## 유효성 검사
	@terraform -chdir=$(ENV_DIR) validate && echo "$(GREEN)[$(ENV)] 유효성 검사 통과$(RESET)"

check: fmt validate ## fmt + validate

output: ## 출력값 확인
	@terraform -chdir=$(ENV_DIR) output

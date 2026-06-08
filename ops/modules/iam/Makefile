###############################################################################
### Terraform IAM 관리 Makefile
### 사용법: make <target> ENV=<dev|prod>
### 예시:   make plan ENV=dev
###         make apply ENV=prod
###############################################################################

# 기본 환경 설정
ENV ?= dev

# 환경별 디렉토리 경로
ENV_DIR := envs/$(ENV)

# 색상 출력 설정
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

# ENV 유효성 검사
.PHONY: check-env
check-env:
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)[ERROR] ENV 값이 올바르지 않습니다. dev 또는 prod를 사용하세요.$(RESET)"; \
		echo "$(YELLOW)사용법: make <target> ENV=<dev|prod>$(RESET)"; \
		exit 1; \
	fi
	@if [ ! -d "$(ENV_DIR)" ]; then \
		echo "$(RED)[ERROR] 디렉토리가 존재하지 않습니다: $(ENV_DIR)$(RESET)"; \
		exit 1; \
	fi
	@echo "$(CYAN)[INFO] 환경: $(ENV) | 디렉토리: $(ENV_DIR)$(RESET)"

### Terraform 초기화
.PHONY: init
init: check-env
	@echo "$(GREEN)[INIT] Terraform 초기화 - 환경: $(ENV)$(RESET)"
	terraform -chdir=$(ENV_DIR) init

### 실행 계획 확인
.PHONY: plan
plan: check-env
	@echo "$(GREEN)[PLAN] 변경 계획 확인 - 환경: $(ENV)$(RESET)"
	terraform -chdir=$(ENV_DIR) plan -out=tfplan

### 변경 사항 적용 (확인 필요)
.PHONY: apply
apply: check-env
	@echo "$(YELLOW)[APPLY] 변경 사항 적용 - 환경: $(ENV)$(RESET)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)[WARNING] 프로덕션 환경입니다! 계속하려면 'yes'를 입력하세요.$(RESET)"; \
		read -r confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "취소되었습니다."; \
			exit 1; \
		fi; \
	fi
	terraform -chdir=$(ENV_DIR) apply tfplan

### 변경 사항 자동 적용 (CI/CD용 - 확인 없음)
.PHONY: apply-auto
apply-auto: check-env
	@echo "$(YELLOW)[APPLY-AUTO] 자동 적용 - 환경: $(ENV)$(RESET)"
	terraform -chdir=$(ENV_DIR) apply -auto-approve

### 리소스 삭제 (주의!)
.PHONY: destroy
destroy: check-env
	@echo "$(RED)[DESTROY] 리소스 삭제 - 환경: $(ENV)$(RESET)"
	@echo "$(RED)[WARNING] 모든 리소스가 삭제됩니다! 계속하려면 'destroy'를 입력하세요.$(RESET)"
	@read -r confirm; \
	if [ "$$confirm" != "destroy" ]; then \
		echo "취소되었습니다."; \
		exit 1; \
	fi
	terraform -chdir=$(ENV_DIR) destroy

### 코드 포맷팅
.PHONY: fmt
fmt:
	@echo "$(GREEN)[FMT] Terraform 파일 포맷팅$(RESET)"
	terraform fmt -recursive

### 포맷팅 검사 (CI용)
.PHONY: fmt-check
fmt-check:
	@echo "$(GREEN)[FMT-CHECK] Terraform 포맷 검사$(RESET)"
	terraform fmt -recursive -check

### 유효성 검사
.PHONY: validate
validate: check-env
	@echo "$(GREEN)[VALIDATE] Terraform 유효성 검사 - 환경: $(ENV)$(RESET)"
	terraform -chdir=$(ENV_DIR) validate

### 출력값 확인
.PHONY: output
output: check-env
	@echo "$(GREEN)[OUTPUT] 출력값 확인 - 환경: $(ENV)$(RESET)"
	terraform -chdir=$(ENV_DIR) output

### 전체 검사 (fmt-check + validate + plan)
.PHONY: check
check: fmt-check validate plan
	@echo "$(GREEN)[CHECK] 전체 검사 완료$(RESET)"

### 도움말
.PHONY: help
help:
	@echo ""
	@echo "$(CYAN)Terraform IAM 관리 Makefile$(RESET)"
	@echo ""
	@echo "$(YELLOW)사용법:$(RESET) make <target> ENV=<dev|prod>"
	@echo ""
	@echo "$(GREEN)타겟 목록:$(RESET)"
	@echo "  init        - Terraform 초기화"
	@echo "  plan        - 변경 계획 확인"
	@echo "  apply       - 변경 사항 적용 (확인 필요)"
	@echo "  apply-auto  - 자동 적용 (CI/CD용)"
	@echo "  destroy     - 리소스 삭제 (주의!)"
	@echo "  fmt         - 코드 포맷팅"
	@echo "  fmt-check   - 포맷 검사"
	@echo "  validate    - 유효성 검사"
	@echo "  output      - 출력값 확인"
	@echo "  check       - 전체 검사 (fmt + validate + plan)"
	@echo ""
	@echo "$(GREEN)예시:$(RESET)"
	@echo "  make init ENV=dev"
	@echo "  make plan ENV=prod"
	@echo "  make apply ENV=dev"
	@echo ""

.DEFAULT_GOAL := help

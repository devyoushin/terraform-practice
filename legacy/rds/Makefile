### ============================================================
### Makefile
### Terraform 환경별 배포 자동화
### 사용법: make <target> ENV=<환경>
### 예시:   make plan ENV=dev
###          make apply ENV=staging
###          make destroy ENV=dev
### ============================================================

### 기본 환경값 (미지정 시 dev)
ENV ?= dev

### 환경별 작업 디렉토리
ENV_DIR := envs/$(ENV)

### 색상 출력 설정
BOLD  := \033[1m
RED   := \033[31m
GREEN := \033[32m
YELLOW:= \033[33m
RESET := \033[0m

### 환경 유효성 검사
.PHONY: _check-env
_check-env:
	@if [ "$(ENV)" != "dev" ] && [ "$(ENV)" != "staging" ] && [ "$(ENV)" != "prod" ]; then \
		echo "$(RED)오류: ENV는 dev, staging, prod 중 하나여야 합니다. (현재: $(ENV))$(RESET)"; \
		exit 1; \
	fi
	@if [ ! -d "$(ENV_DIR)" ]; then \
		echo "$(RED)오류: 디렉토리 $(ENV_DIR) 가 존재하지 않습니다.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)환경: $(ENV) | 디렉토리: $(ENV_DIR)$(RESET)"

### ---------------------------------------------------------------
### init: Terraform 초기화
### ---------------------------------------------------------------
.PHONY: init
init: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 초기화 중...$(RESET)"
	cd $(ENV_DIR) && terraform init -upgrade

### ---------------------------------------------------------------
### fmt: 코드 포맷팅
### ---------------------------------------------------------------
.PHONY: fmt
fmt:
	@echo "$(BOLD)Terraform 코드 포맷팅 중...$(RESET)"
	terraform fmt -recursive .

### ---------------------------------------------------------------
### validate: 설정 유효성 검사
### ---------------------------------------------------------------
.PHONY: validate
validate: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 유효성 검사 중...$(RESET)"
	cd $(ENV_DIR) && terraform validate

### ---------------------------------------------------------------
### check: fmt + validate 일괄 실행
### ---------------------------------------------------------------
.PHONY: check
check: fmt validate
	@echo "$(GREEN)코드 포맷팅 및 유효성 검사 완료$(RESET)"

### ---------------------------------------------------------------
### plan: 변경 계획 확인
### ---------------------------------------------------------------
.PHONY: plan
plan: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 플랜 생성 중...$(RESET)"
	cd $(ENV_DIR) && terraform plan -out=tfplan

### ---------------------------------------------------------------
### apply: 플랜 기반 변경 적용 (승인 필요)
### ---------------------------------------------------------------
.PHONY: apply
apply: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 변경 적용 중... (플랜 파일 사용)$(RESET)"
	@if [ ! -f "$(ENV_DIR)/tfplan" ]; then \
		echo "$(YELLOW)경고: 플랜 파일이 없습니다. 먼저 'make plan ENV=$(ENV)'을 실행하세요.$(RESET)"; \
		exit 1; \
	fi
	cd $(ENV_DIR) && terraform apply tfplan

### ---------------------------------------------------------------
### apply-auto: 자동 승인 적용 (CI/CD 파이프라인용)
### ---------------------------------------------------------------
.PHONY: apply-auto
apply-auto: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 자동 승인 적용 중...$(RESET)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)경고: prod 환경에서는 apply-auto 사용을 권장하지 않습니다!$(RESET)"; \
		read -p "계속 진행하시겠습니까? (yes/no): " confirm; \
		if [ "$$confirm" != "yes" ]; then exit 1; fi; \
	fi
	cd $(ENV_DIR) && terraform apply -auto-approve

### ---------------------------------------------------------------
### destroy: 리소스 삭제 (신중하게 사용)
### ---------------------------------------------------------------
.PHONY: destroy
destroy: _check-env
	@echo "$(RED)$(BOLD)[$(ENV)] Terraform 리소스 삭제 중... 이 작업은 되돌릴 수 없습니다!$(RESET)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)경고: prod 환경 리소스를 삭제하려 합니다!$(RESET)"; \
		read -p "삭제를 계속하려면 'yes'를 입력하세요: " confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "취소되었습니다."; \
			exit 1; \
		fi; \
	fi
	cd $(ENV_DIR) && terraform destroy

### ---------------------------------------------------------------
### output: 출력값 조회
### ---------------------------------------------------------------
.PHONY: output
output: _check-env
	@echo "$(BOLD)[$(ENV)] Terraform 출력값 조회$(RESET)"
	cd $(ENV_DIR) && terraform output

### ---------------------------------------------------------------
### help: 사용법 출력
### ---------------------------------------------------------------
.PHONY: help
help:
	@echo "$(BOLD)Terraform RDS 배포 Makefile$(RESET)"
	@echo ""
	@echo "사용법: make <target> ENV=<환경>"
	@echo "환경:   dev | staging | prod (기본값: dev)"
	@echo ""
	@echo "타겟 목록:"
	@echo "  $(GREEN)init$(RESET)        - Terraform 초기화"
	@echo "  $(GREEN)fmt$(RESET)         - 전체 코드 포맷팅"
	@echo "  $(GREEN)validate$(RESET)    - 설정 유효성 검사"
	@echo "  $(GREEN)check$(RESET)       - fmt + validate 일괄 실행"
	@echo "  $(GREEN)plan$(RESET)        - 변경 계획 확인 (tfplan 파일 생성)"
	@echo "  $(GREEN)apply$(RESET)       - 플랜 기반 변경 적용 (승인 필요)"
	@echo "  $(GREEN)apply-auto$(RESET)  - 자동 승인 적용 (CI/CD용)"
	@echo "  $(GREEN)destroy$(RESET)     - 리소스 삭제 (주의!)"
	@echo "  $(GREEN)output$(RESET)      - 출력값 조회"
	@echo ""
	@echo "예시:"
	@echo "  make init ENV=dev"
	@echo "  make plan ENV=staging"
	@echo "  make apply ENV=prod"
	@echo "  make output ENV=dev"

### 기본 타겟
.DEFAULT_GOAL := help

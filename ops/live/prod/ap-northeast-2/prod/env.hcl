### =============================================================================
### prod/env.hcl — PROD 환경 선언
###
### 루트 terragrunt.hcl 에서 find_in_parent_folders("env.hcl") 로 자동 탐색됩니다.
### prod/ 하위의 모든 모듈이 이 파일을 공유합니다.
### =============================================================================

locals {
  environment = "prod"
  owner       = "infra-team"
  cost_center = "infra-team"
}

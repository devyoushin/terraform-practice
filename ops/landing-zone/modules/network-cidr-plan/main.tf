### =============================================================================
### modules/network-cidr-plan/main.tf
### 서비스별 /24 및 환경별 /26 CIDR 계산
### =============================================================================

locals {
  service_plan = {
    for key, service in var.services : key => {
      name          = service.name
      domain        = service.domain
      owner         = service.owner
      criticality   = service.criticality
      service_cidr  = cidrsubnet(var.base_cidr, 8, service.index)
      dev_cidr      = cidrsubnet(cidrsubnet(var.base_cidr, 8, service.index), 2, 0)
      stg_cidr      = cidrsubnet(cidrsubnet(var.base_cidr, 8, service.index), 2, 1)
      prd_cidr      = cidrsubnet(cidrsubnet(var.base_cidr, 8, service.index), 2, 2)
      reserved_cidr = cidrsubnet(cidrsubnet(var.base_cidr, 8, service.index), 2, 3)
    }
  }

  service_indices = [for _, service in var.services : service.index]
}

resource "terraform_data" "validate_service_index" {
  input = local.service_indices

  lifecycle {
    precondition {
      condition     = length(local.service_indices) == length(toset(local.service_indices))
      error_message = "서비스 index는 중복될 수 없습니다."
    }

    precondition {
      condition     = alltrue([for index in local.service_indices : index >= 0 && index <= 255])
      error_message = "10.100.0.0/16에서 /24를 할당하려면 index는 0부터 255 사이여야 합니다."
    }
  }
}

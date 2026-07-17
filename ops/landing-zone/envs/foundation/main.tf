### =============================================================================
### envs/foundation/main.tf
### 엔터프라이즈 Landing Zone foundation 구성
### =============================================================================

locals {
  organization_catalog = jsondecode(file("${path.module}/../../catalog/organization.json"))
  service_catalog      = yamldecode(file("${path.module}/../../catalog/services.yaml"))

  environments = local.service_catalog.environments

  services = {
    for service in local.service_catalog.services : service.key => {
      name        = service.name
      domain      = service.domain
      index       = service.index
      owner       = service.owner
      criticality = service.criticality
    }
  }

  network_plan = {
    for key, service in local.services : key => {
      service_cidr  = cidrsubnet(local.service_catalog.base_cidr, 8, service.index)
      dev_cidr      = cidrsubnet(cidrsubnet(local.service_catalog.base_cidr, 8, service.index), 2, 0)
      stg_cidr      = cidrsubnet(cidrsubnet(local.service_catalog.base_cidr, 8, service.index), 2, 1)
      prd_cidr      = cidrsubnet(cidrsubnet(local.service_catalog.base_cidr, 8, service.index), 2, 2)
      reserved_cidr = cidrsubnet(cidrsubnet(local.service_catalog.base_cidr, 8, service.index), 2, 3)
    }
  }

  service_accounts_by_env = [
    for env in local.environments : {
      for key, service in local.services : "${key}-${env}" => {
        name                       = "lz-${key}-${env}"
        email                      = "aws-${key}-${env}@${local.organization_catalog.email_domain}"
        ou_key                     = "workloads-${env}"
        role_name                  = "OrganizationAccountAccessRole"
        close_on_deletion          = false
        iam_user_access_to_billing = "DENY"
        tags = {
          AccountType = "workload"
          Service     = key
          Domain      = service.domain
          Environment = env
          Owner       = service.owner
          Criticality = service.criticality
          VpcCidr     = local.network_plan[key]["${env}_cidr"]
        }
      }
    }
  ]

  service_accounts = merge(local.service_accounts_by_env...)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    Scope       = "landing-zone"
  }
}

module "organization" {
  source = "../../modules/organization"

  project_name        = var.project_name
  environment         = var.environment
  common_tags         = local.common_tags
  create_organization = var.create_organization
  root_ous            = local.organization_catalog.root_ous
  child_ous           = local.organization_catalog.child_ous

  accounts = merge(
    local.organization_catalog.foundation_accounts,
    local.service_accounts
  )
}

module "network_cidr_plan" {
  source = "../../modules/network-cidr-plan"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
  base_cidr    = local.service_catalog.base_cidr
  services     = local.services
}

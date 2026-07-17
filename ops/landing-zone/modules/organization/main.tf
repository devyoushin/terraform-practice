### =============================================================================
### modules/organization/main.tf
### AWS Organizations OU 및 계정 생성
### =============================================================================

data "aws_organizations_organization" "current" {
  count = var.create_organization ? 0 : 1
}

resource "aws_organizations_organization" "this" {
  count = var.create_organization ? 1 : 0

  aws_service_access_principals = [
    "account.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]

  enabled_policy_types = var.enabled_policy_types
  feature_set          = "ALL"
}

locals {
  root_id = var.create_organization ? aws_organizations_organization.this[0].roots[0].id : data.aws_organizations_organization.current[0].roots[0].id
}

### ---------------------------------------------------------------
### 1단계 OU
### ---------------------------------------------------------------
resource "aws_organizations_organizational_unit" "root" {
  for_each = var.root_ous

  name      = each.value.name
  parent_id = local.root_id
  tags      = merge(var.common_tags, each.value.tags)
}

### ---------------------------------------------------------------
### 2단계 OU
### ---------------------------------------------------------------
resource "aws_organizations_organizational_unit" "child" {
  for_each = var.child_ous

  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.root[each.value.parent_ou_key].id
  tags      = merge(var.common_tags, each.value.tags)
}

locals {
  ou_ids = merge(
    { for key, ou in aws_organizations_organizational_unit.root : key => ou.id },
    { for key, ou in aws_organizations_organizational_unit.child : key => ou.id }
  )
}

### ---------------------------------------------------------------
### AWS Account
### ---------------------------------------------------------------
resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  parent_id                  = local.ou_ids[each.value.ou_key]
  role_name                  = each.value.role_name
  close_on_deletion          = each.value.close_on_deletion
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  tags                       = merge(var.common_tags, each.value.tags)

  lifecycle {
    prevent_destroy = true
  }
}

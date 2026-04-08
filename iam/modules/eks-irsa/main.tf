###############################################################################
### EKS IRSA (IAM Roles for Service Accounts) 모듈
### - EKS Pod에 최소 권한 IAM Role 부여
### - 특정 Namespace/ServiceAccount 조합에만 AssumeRole 허용
###############################################################################

### OIDC Provider ARN에서 issuer URL 추출
locals {
  # ARN 형식: arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/XXXXX
  # issuer 형식: oidc.eks.region.amazonaws.com/id/XXXXX
  oidc_issuer = replace(
    var.oidc_provider_arn,
    "/^arn:[^:]+:iam::[^:]+:oidc-provider\\//",
    ""
  )
}

### AssumeRoleWithWebIdentity 정책 문서 (EKS ServiceAccount OIDC)
data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    sid     = "EKSIRSAAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # 특정 Namespace의 특정 ServiceAccount만 허용 (최소 권한 원칙)
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

### IAM Role 생성
resource "aws_iam_role" "irsa_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
  description        = "IRSA Role for ${var.namespace}/${var.service_account_name}"

  tags = merge(var.common_tags, {
    Name                                        = var.role_name
    "eks.amazonaws.com/namespace"               = var.namespace
    "eks.amazonaws.com/service-account-name"    = var.service_account_name
  })
}

### 정책 연결 (for_each로 다수 정책 지원)
resource "aws_iam_role_policy_attachment" "irsa_policies" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.irsa_role.name
  policy_arn = each.value
}

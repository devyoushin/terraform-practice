###############################################################################
### CI/CD IAM Role 모듈 (GitHub Actions OIDC)
### - 장기 자격증명 없이 OIDC 토큰으로 AWS 접근
### - 특정 GitHub Org/Repo에 대해서만 AssumeRoleWithWebIdentity 허용
###############################################################################

### GitHub Actions OIDC Provider 생성 (이미 존재하면 create_oidc_provider = false)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]

  # GitHub Actions OIDC 인증서 thumbprint (AWS 공식 제공)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = merge(var.common_tags, {
    Name = "github-actions-oidc-provider"
  })
}

### OIDC Provider ARN 로컬 값 (신규 생성 또는 기존 ARN 사용)
locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

### AssumeRoleWithWebIdentity 정책 문서 (GitHub Actions OIDC)
data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 특정 GitHub Org/Repo의 워크플로우만 허용 (브랜치/태그 와일드카드 지원)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

### IAM Role 생성
resource "aws_iam_role" "cicd_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
  description        = "GitHub Actions OIDC CI/CD Role for ${var.github_org}/${var.github_repo}"

  tags = merge(var.common_tags, {
    Name = var.role_name
  })
}

### 관리형/커스텀 정책 연결 (for_each로 다수 정책 지원)
resource "aws_iam_role_policy_attachment" "cicd_policies" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.cicd_role.name
  policy_arn = each.value
}

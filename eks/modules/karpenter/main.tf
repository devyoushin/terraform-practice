terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

locals {
  # OIDC ARN(arn:aws:iam::ACCOUNT:oidc-provider/ISSUER)에서 ISSUER 부분만 추출
  oidc_issuer = replace(var.oidc_provider_arn, "/^arn:[^:]+:iam::[^:]+:oidc-provider\\//", "")

  interruption_rules = {
    spot_interruption     = { source = "aws.ec2",    detail_type = "EC2 Spot Instance Interruption Warning" }
    instance_rebalance    = { source = "aws.ec2",    detail_type = "EC2 Instance Rebalance Recommendation" }
    instance_state_change = { source = "aws.ec2",    detail_type = "EC2 Instance State-change Notification" }
    health_event          = { source = "aws.health", detail_type = "AWS Health Event" }
  }
}

# ============================================================
# Karpenter 컨트롤러 IAM Role (IRSA - Pod에 AWS 권한 부여)
# ============================================================
resource "aws_iam_role" "karpenter" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:kube-system:karpenter"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"
  role = aws_iam_role.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KarpenterEC2"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
        ]
        Resource = "*"
      },
      {
        Sid    = "KarpenterIAM"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
        ]
        Resource = "*"
      },
      {
        Sid      = "KarpenterSSM"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:*:*:parameter/aws/service/*"
      },
      {
        Sid      = "KarpenterPricing"
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = "*"
      },
      {
        Sid    = "KarpenterInterruption"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
        ]
        Resource = aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}

# ============================================================
# Karpenter 노드 IAM Role (Karpenter가 띄운 EC2가 클러스터에 조인하기 위해 필요)
# ============================================================
resource "aws_iam_role" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node"
  role = aws_iam_role.karpenter_node.name
}

# ============================================================
# Spot 인터럽션 처리용 SQS 큐 + EventBridge 규칙
# ============================================================
resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.cluster_name}-karpenter-interruption"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.karpenter_interruption.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = local.interruption_rules

  name = "${var.cluster_name}-karpenter-${each.key}"
  event_pattern = jsonencode({
    source      = [each.value.source]
    detail-type = [each.value.detail_type]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each = aws_cloudwatch_event_rule.karpenter_interruption

  rule      = each.value.name
  target_id = "karpenter-interruption-queue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

# ============================================================
# Karpenter Helm 설치
# ============================================================
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.1.1" # ← 최신 버전 확인: https://gallery.ecr.aws/karpenter/karpenter
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter.arn
  }
  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }
  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter_interruption.name
  }
}

# ============================================================
# EC2NodeClass: Karpenter 노드에 사용할 AMI/서브넷/보안그룹 설정
# ============================================================
resource "kubectl_manifest" "node_class" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata   = { name = "default" }
    spec = {
      role             = aws_iam_role.karpenter_node.name
      amiSelectorTerms = [{ alias = "al2023@latest" }]
      subnetSelectorTerms = [{
        tags = { "karpenter.sh/discovery" = var.cluster_name }
      }]
      securityGroupSelectorTerms = [{
        tags = { "karpenter.sh/discovery" = var.cluster_name }
      }]
    }
  })

  depends_on = [helm_release.karpenter]
}

# ============================================================
# NodePool: Karpenter가 프로비저닝할 노드 스펙 및 제한 설정
# ============================================================
resource "kubectl_manifest" "node_pool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "default" }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand", "spot"] # ← spot 제거 시 on-demand만 사용
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["t3.medium", "t3.large", "t3.xlarge", "m5.large"] # ← 허용할 인스턴스 타입
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
          ]
        }
      }
      limits = {
        cpu    = "1000"    # ← 클러스터 전체 최대 CPU 합산 제한
        memory = "1000Gi" # ← 클러스터 전체 최대 메모리 합산 제한
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
      }
    }
  })

  depends_on = [kubectl_manifest.node_class]
}

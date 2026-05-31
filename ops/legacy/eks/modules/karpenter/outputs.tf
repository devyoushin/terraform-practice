output "karpenter_role_arn" {
  description = "Karpenter 컨트롤러 IAM Role ARN"
  value       = aws_iam_role.karpenter.arn
}

output "node_iam_role_arn" {
  description = "Karpenter 노드 IAM Role ARN (aws_eks_access_entry에 사용)"
  value       = aws_iam_role.karpenter_node.arn
}

output "node_instance_profile_name" {
  description = "Karpenter 노드 Instance Profile 이름"
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "interruption_queue_name" {
  description = "Karpenter Spot 인터럽션 처리용 SQS 큐 이름"
  value       = aws_sqs_queue.karpenter_interruption.name
}

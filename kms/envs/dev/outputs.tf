### =============================================================================
### envs/dev/outputs.tf
### =============================================================================

output "rds_key_arn" {
  description = "RDS 암호화 KMS 키 ARN"
  value       = module.rds_key.key_arn
}

output "rds_key_id" {
  description = "RDS 암호화 KMS 키 ID"
  value       = module.rds_key.key_id
}

output "s3_key_arn" {
  description = "S3 암호화 KMS 키 ARN"
  value       = module.s3_key.key_arn
}

output "s3_key_id" {
  description = "S3 암호화 KMS 키 ID"
  value       = module.s3_key.key_id
}

output "eks_key_arn" {
  description = "EKS 암호화 KMS 키 ARN"
  value       = module.eks_key.key_arn
}

output "eks_key_id" {
  description = "EKS 암호화 KMS 키 ID"
  value       = module.eks_key.key_id
}

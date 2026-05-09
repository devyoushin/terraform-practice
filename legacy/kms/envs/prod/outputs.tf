output "rds_key_arn" { value = module.rds_key.key_arn; description = "RDS KMS 키 ARN" }
output "rds_key_id" { value = module.rds_key.key_id; description = "RDS KMS 키 ID" }
output "s3_key_arn" { value = module.s3_key.key_arn; description = "S3 KMS 키 ARN" }
output "s3_key_id" { value = module.s3_key.key_id; description = "S3 KMS 키 ID" }
output "eks_key_arn" { value = module.eks_key.key_arn; description = "EKS KMS 키 ARN" }
output "eks_key_id" { value = module.eks_key.key_id; description = "EKS KMS 키 ID" }

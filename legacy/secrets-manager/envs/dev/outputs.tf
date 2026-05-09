output "rds_secret_arn" { value = module.rds_secret.secret_arn; description = "RDS 시크릿 ARN" }
output "rds_secret_id" { value = module.rds_secret.secret_id; description = "RDS 시크릿 ID" }
output "app_secret_arn" { value = module.app_secret.secret_arn; description = "앱 시크릿 ARN" }
output "app_secret_id" { value = module.app_secret.secret_id; description = "앱 시크릿 ID" }

output "sessions_table_name" { value = module.sessions_table.table_name; description = "세션 테이블 이름" }
output "sessions_table_arn" { value = module.sessions_table.table_arn; description = "세션 테이블 ARN" }
output "state_lock_table_name" { value = module.state_lock_table.table_name; description = "Terraform 상태 잠금 테이블 이름" }
output "state_lock_table_arn" { value = module.state_lock_table.table_arn; description = "Terraform 상태 잠금 테이블 ARN" }

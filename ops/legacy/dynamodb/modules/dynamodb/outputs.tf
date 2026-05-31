output "table_id" { value = aws_dynamodb_table.this.id; description = "DynamoDB 테이블 이름 (ID)" }
output "table_arn" { value = aws_dynamodb_table.this.arn; description = "DynamoDB 테이블 ARN" }
output "table_name" { value = aws_dynamodb_table.this.name; description = "DynamoDB 테이블 이름" }
output "stream_arn" {
  description = "DynamoDB Streams ARN. enable_stream = false이면 null."
  value       = var.enable_stream ? aws_dynamodb_table.this.stream_arn : null
}

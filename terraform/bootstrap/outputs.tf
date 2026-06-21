output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Use this in environments/*/backend.tf as the 'bucket' value"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Use this in environments/*/backend.tf as the 'dynamodb_table' value"
}

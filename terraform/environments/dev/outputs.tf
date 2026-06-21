output "website_url" {
  value = var.enable_custom_domain ? "https://${var.subdomain}.${var.root_domain_name}" : "https://${module.cloudfront.distribution_domain_name}"
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "s3_bucket_name" {
  value = module.s3_static_site.bucket_id
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

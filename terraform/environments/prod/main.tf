###############################################################################
# DEV ENVIRONMENT
# Wires every module together. Mirrors prod/main.tf almost exactly — the
# difference is in terraform.tfvars (lower thresholds, shorter retention,
# custom domain usually off in dev to save the ACM/Route53 step while
# iterating).
###############################################################################

# ---------------------------------------------------------------------------
# 1. DynamoDB — stores visitor count / app data
# ---------------------------------------------------------------------------
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name                    = "${var.project_name}-${var.environment}-data"
  hash_key                      = "id"
  enable_point_in_time_recovery = true
  project_name                  = var.project_name
  environment                   = var.environment
}

# ---------------------------------------------------------------------------
# 2. Lambda — backend logic, least-privilege role scoped to the table above
# ---------------------------------------------------------------------------
module "lambda" {
  source = "../../modules/lambda"

  function_name       = "${var.project_name}-${var.environment}-visitor-counter"
  source_dir          = "${path.module}/../../../lambda/src"
  dynamodb_table_arn  = module.dynamodb.table_arn
  log_retention_days  = 30
  project_name        = var.project_name
  environment         = var.environment

  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
  }
}

# ---------------------------------------------------------------------------
# 3. API Gateway — public HTTP endpoint in front of Lambda
# ---------------------------------------------------------------------------
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name          = var.project_name
  environment           = var.environment
  route_key             = "GET /visitors"
  lambda_invoke_arn     = module.lambda.invoke_arn
  lambda_function_name  = module.lambda.function_name
  cors_allow_origins    = var.enable_custom_domain ? ["https://${var.subdomain}.${var.root_domain_name}"] : ["*"]
  throttling_burst_limit = 10
  throttling_rate_limit  = 5
}

# ---------------------------------------------------------------------------
# 4. S3 — private bucket for the static frontend
#    (bucket policy references the CloudFront distribution ARN, created next)
# ---------------------------------------------------------------------------
module "s3_static_site" {
  source = "../../modules/s3-static-site"

  bucket_name                 = "${var.project_name}-${var.environment}-site-${var.account_id}"
  project_name                = var.project_name
  environment                 = var.environment
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

# ---------------------------------------------------------------------------
# 5. ACM certificate — only created if a custom domain is enabled
# ---------------------------------------------------------------------------
module "acm" {
  source = "../../modules/acm-certificate"
  count  = var.enable_custom_domain ? 1 : 0

  domain_name                = "${var.subdomain}.${var.root_domain_name}"
  subject_alternative_names  = []
  route53_zone_id            = data.aws_route53_zone.root[0].zone_id
  project_name               = var.project_name
  environment                = var.environment
}

data "aws_route53_zone" "root" {
  count        = var.enable_custom_domain ? 1 : 0
  name         = var.root_domain_name
  private_zone = false
}

# ---------------------------------------------------------------------------
# 6. CloudFront — CDN in front of the S3 bucket
# ---------------------------------------------------------------------------
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name                   = var.project_name
  environment                    = var.environment
  s3_bucket_regional_domain_name = "${var.project_name}-${var.environment}-site-${var.account_id}.s3.${var.aws_region}.amazonaws.com"
  enable_custom_domain           = var.enable_custom_domain
  domain_aliases                 = var.enable_custom_domain ? ["${var.subdomain}.${var.root_domain_name}"] : []
  acm_certificate_arn            = var.enable_custom_domain ? module.acm[0].certificate_arn : null
}

# ---------------------------------------------------------------------------
# 7. Route53 — alias record, only if custom domain is enabled
# ---------------------------------------------------------------------------
module "route53" {
  source = "../../modules/route53"
  count  = var.enable_custom_domain ? 1 : 0

  root_domain_name          = var.root_domain_name
  record_name               = "${var.subdomain}.${var.root_domain_name}"
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id
}

# ---------------------------------------------------------------------------
# 8. Monitoring — alarms + budget guard
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment              = var.environment
  alert_email              = var.alert_email
  lambda_function_name     = module.lambda.function_name
  api_gateway_id           = module.api_gateway.api_id
  dynamodb_table_name      = module.dynamodb.table_name
  lambda_error_threshold   = 1
  api_5xx_threshold        = 1
  enable_budget_alert      = true
  monthly_budget_usd       = var.monthly_budget_usd
}

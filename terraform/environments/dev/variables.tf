variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "serverless-portfolio"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "account_id" {
  description = "Your AWS account ID, used to make the S3 bucket name globally unique"
  type        = string
}

variable "enable_custom_domain" {
  description = "Set true once you own a domain + Route53 hosted zone. False uses the free *.cloudfront.net URL."
  type        = bool
  default     = false
}

variable "root_domain_name" {
  description = "e.g. gentrit.me"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "e.g. dev -> dev.gentrit.me"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "monthly_budget_usd" {
  type    = number
  default = 5
}

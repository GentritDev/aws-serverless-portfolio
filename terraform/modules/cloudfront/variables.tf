variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_regional_domain_name" {
  type = string
}

variable "enable_custom_domain" {
  description = "If false, the distribution uses the default *.cloudfront.net domain and no ACM/Route53 are required (fully $0 path for anyone without a registered domain)."
  type        = bool
  default     = false
}

variable "domain_aliases" {
  type    = list(string)
  default = []
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

variable "root_domain_name" {
  description = "Domain whose hosted zone already exists, e.g. gentrit.me"
  type        = string
}

variable "record_name" {
  description = "Full record name to create, e.g. dev.gentrit.me or gentrit.me"
  type        = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront's fixed hosted zone ID (always Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name"
  type        = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution allowed to read this bucket"
  type        = string
}

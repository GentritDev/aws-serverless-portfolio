variable "domain_name" {
  description = "Primary domain for the certificate, e.g. dev.gentrit.me"
  type        = string
}

variable "subject_alternative_names" {
  description = "Extra domains covered by the certificate (e.g. www.gentrit.me)"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

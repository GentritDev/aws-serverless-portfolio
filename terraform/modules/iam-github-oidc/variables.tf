variable "project_name" {
  type = string
}

variable "role_name" {
  type    = string
  default = "github-actions-deploy-role"
}

variable "create_oidc_provider" {
  description = "Set to false if the github OIDC provider already exists in this AWS account"
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  type    = string
  default = ""
}

variable "allowed_subjects" {
  description = "GitHub OIDC subject patterns allowed to assume this role, e.g. [\"repo:GentritDev/aws-serverless-portfolio:ref:refs/heads/main\", \"repo:GentritDev/aws-serverless-portfolio:ref:refs/heads/develop\"]"
  type        = list(string)
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

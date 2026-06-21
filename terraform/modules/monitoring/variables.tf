variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  description = "Email to receive SNS alarm + budget notifications. Leave empty to skip."
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  type = string
}

variable "api_gateway_id" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "lambda_error_threshold" {
  type    = number
  default = 1
}

variable "api_5xx_threshold" {
  type    = number
  default = 1
}

variable "enable_budget_alert" {
  type    = bool
  default = true
}

variable "monthly_budget_usd" {
  type    = number
  default = 5
}

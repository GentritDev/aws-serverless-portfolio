variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "$default"
}

variable "route_key" {
  type    = string
  default = "GET /visitors"
}

variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "cors_allow_origins" {
  type    = list(string)
  default = ["*"] # tighten to your real domain in prod.tfvars
}

variable "throttling_burst_limit" {
  type    = number
  default = 10
}

variable "throttling_rate_limit" {
  type    = number
  default = 5
}

variable "log_retention_days" {
  type    = number
  default = 14
}

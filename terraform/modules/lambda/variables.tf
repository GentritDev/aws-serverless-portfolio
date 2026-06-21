variable "function_name" {
  type = string
}

variable "source_dir" {
  description = "Path to the lambda source code directory to zip"
  type        = string
}

variable "handler" {
  type    = string
  default = "handler.handler"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 5
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "dynamodb_table_arn" {
  type = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

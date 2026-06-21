variable "table_name" {
  type = string
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "enable_point_in_time_recovery" {
  description = "Recommended for prod, optional for dev to save nothing extra (PITR is included in free tier for low usage, but kept as a toggle for clarity)."
  type        = bool
  default     = false
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

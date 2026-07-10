variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
  default = {
    "owner"      = "me",
    "managed_by" = "terraform"
  }
}

variable "name" {
  type        = string
  description = "Name prefix"
  default     = "function-app"
}
variable "log_analytics_retention_days" {
  description = "Retention period in days for the Log Analytics workspace."
  type        = number
  default     = 30
}

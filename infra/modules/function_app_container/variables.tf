
variable "resource_group_id" {
  description = "ID of the resource group to create for all resources."
  type        = string
}
variable "resource_group_name" {
  description = "Name of the resource group to create for all resources."
  type        = string
}



variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}



variable "suffix" {
  description = "A random suffix, appended for global uniqueness."
  type        = string
}



variable "container_image" {

  description = "Docker container image to deploy to the function app."

  type = string

  default = "mcr.microsoft.com/k8se/quickstart-functions:latest"

}



variable "target_port" {

  description = "Container ingress target port."

  type = number

  default = 80

}



variable "cpu_core" {

  description = "Number of CPU cores for the container (max two decimals). CPU:memory ratio must be 1:2."

  type = number

  default = 0.5

}



variable "memory_size" {

  description = "Memory in GiB allocated to the container (max two decimals). CPU:memory ratio must be 1:2."

  type = number

  default = 1

}



variable "min_replicas" {

  description = "Minimum number of replicas."

  type = number

  default = 1

}



variable "max_replicas" {

  description = "Maximum number of replicas."

  type = number

  default = 3

}



variable "functions_runtime" {

  description = "Azure Functions worker runtime (e.g. python, dotnet-isolated, node)."

  type = string

  default = "python"

}



variable "log_analytics_ws_id" {
  description = "ID of the Log Analytics workspace for telemetry of container."
  type        = string
}

variable "container_env_id" {
  description = "ID of managed container environment for function app container."
  type        = string
}



variable "tags" {

  description = "Tags applied to all resources."

  type = map(string)

  default = {}

}

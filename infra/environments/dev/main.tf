## Deploys base infra for Azure Functions on Azure Container Apps
data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length      = 4
  min_numeric = 4
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  account_name           = lower("${var.name}${random_string.unique.result}")
  log_analytics_name     = "log-${local.account_name}"
  container_app_env_name = "env-${local.account_name}"

}

resource "azurerm_resource_group" "this" {
  name     = "${local.account_name}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "containerRegistryTools"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}
# Log Analytics workspace backing the Container Apps environment and Application Insights.
resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# Container Apps environment with a Consumption workload profile.
resource "azurerm_container_app_environment" "this" {
  name                       = local.container_app_env_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
  tags = var.tags
}

module "function_app" {
  source              = "../../modules/function_app_container"
  location            = var.location
  resource_group_id   = azurerm_resource_group.this.id
  suffix              = random_string.unique.result
  resource_group_name = azurerm_resource_group.this.name
  log_analytics_ws_id = azurerm_log_analytics_workspace.this.id
  container_env_id    = azurerm_container_app_environment.this.id
  tags                = var.tags
}

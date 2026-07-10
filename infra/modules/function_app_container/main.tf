
locals {
  storage_account_name      = "st${var.suffix}"
  function_app_name         = "app-${var.suffix}"
  application_insights_name = "app-${var.suffix}"
}




# Storage account for the Functions host.
resource "azurerm_storage_account" "this" {
  name                            = local.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags
}

# Application Insights (workspace-based) for the function app.
resource "azurerm_application_insights" "this" {
  name                = local.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_ws_id
  tags                = var.tags
}

# Functions host runtime state (blobs, leases).
resource "azurerm_role_assignment" "storage_blob" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.function_app.identity[0].principal_id
}



# Functions host uses queues for internal coordination and triggers.

resource "azurerm_role_assignment" "storage_queue" {

  scope = azurerm_storage_account.this.id

  role_definition_name = "Storage Queue Data Contributor"

  principal_id = azapi_resource.function_app.identity[0].principal_id

}



# Table storage is used by some triggers/bindings and Durable Functions.

resource "azurerm_role_assignment" "storage_table" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azapi_resource.function_app.identity[0].principal_id
}



# Allows the app to publish telemetry to Application Insights via Entra ID auth.

resource "azurerm_role_assignment" "app_insights_publisher" {
  scope                = azurerm_application_insights.this.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azapi_resource.function_app.identity[0].principal_id
}



# ---------------------------------------------------------------------------
# Function app (native Azure Functions on Container Apps, kind = "functionapp").
# Uses azapi because the azurerm_container_app resource does not expose the
# "kind" property required for the native Functions hosting model.
# ---------------------------------------------------------------------------

resource "azapi_resource" "function_app" {
  type      = "Microsoft.App/containerApps@2024-10-02-preview"
  name      = local.function_app_name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "functionapp"
    properties = {
      managedEnvironmentId = var.container_env_id
      configuration = {
        ingress = {
          external      = true
          targetPort    = var.target_port
          allowInsecure = false
          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
        }
      }
      template = {
        containers = [
          {
            name  = local.function_app_name
            image = var.container_image
            env = [
              # Identity-based connection to storage (no AzureWebJobsStorage secret).
              {
                name  = "AzureWebJobsStorage__accountName"
                value = "https://${azurerm_storage_account.this.name}.core.windows.net/"
              },
              {
                name  = "AzureWebJobsStorage__blobServiceUri"
                value = azurerm_storage_account.this.primary_blob_endpoint
              },
              {
                name  = "AzureWebJobsStorage__queueServiceUri"
                value = azurerm_storage_account.this.primary_queue_endpoint
              },
              {
                name  = "AzureWebJobsStorage__tableServiceUri"
                value = azurerm_storage_account.this.primary_table_endpoint
              },
              {
                name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
                value = azurerm_application_insights.this.connection_string
              },

              # Authenticate App Insights ingestion with the managed identity.
              {
                name  = "APPLICATIONINSIGHTS_AUTHENTICATION_STRING"
                value = "Authorization=AAD"
              },
              {
                name  = "FUNCTIONS_WORKER_RUNTIME"
                value = var.functions_runtime
              }
            ]
            resources = {
              cpu    = var.cpu_core
              memory = "${var.memory_size}Gi"
            }
          }
        ]
        scale = {
          minReplicas = var.min_replicas
          maxReplicas = var.max_replicas
        }
      }
    }
  }

  response_export_values = ["properties.configuration.ingress.fqdn"]
}

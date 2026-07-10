
output "function_app_id" {

  description = "Resource ID of the function container app."

  value = azapi_resource.function_app.id

}



output "function_app_name" {

  description = "Name of the function container app."

  value = azapi_resource.function_app.name

}



output "function_app_fqdn" {

  description = "Public fully-qualified domain name of the function app ingress."

  value = azapi_resource.function_app.output.properties.configuration.ingress.fqdn

}



output "function_app_url" {

  description = "Public HTTPS URL of the function app."

  value = "https://${azapi_resource.function_app.output.properties.configuration.ingress.fqdn}"

}



output "function_app_principal_id" {

  description = "Object ID of the function app's system-assigned managed identity."

  value = azapi_resource.function_app.identity[0].principal_id

}



output "storage_account_name" {

  description = "Name of the storage account backing the Functions host."

  value = azurerm_storage_account.this.name

}



output "application_insights_connection_string" {

  description = "Application Insights connection string."

  value = azurerm_application_insights.this.connection_string

  sensitive = true

}

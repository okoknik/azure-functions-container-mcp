output "acr_login_server" {
  description = "Login server of ACR for function app container."
  value       = azurerm_container_registry.acr.login_server
}
output "function_app_fqdn" {
  description = "Fully qualified domain name of function app."
  value       = module.function_app.function_app_fqdn
}

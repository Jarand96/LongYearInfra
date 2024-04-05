output "url" {
  sensitive = true
  value = "https://${azurerm_linux_function_app.main.default_hostname}/api/${local.function_get_reports}?code=${data.azurerm_function_app_host_keys.main.default_function_key}"
}
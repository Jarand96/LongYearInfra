variable location {
    type = string
    default = "West Europe"   
}

locals {
  function_get_reports = "get_report"
  function_get_report = "get_reports"
  get_reports_url = "https://${azurerm_linux_function_app.main.default_hostname}/api/${local.function_get_reports}?code=${data.azurerm_function_app_host_keys.main.default_function_key}"
  get_report_url = "https://${azurerm_linux_function_app.main.default_hostname}/api/${local.function_get_report}?code=${data.azurerm_function_app_host_keys.main.default_function_key}"
}

# Reasearch Portal function app

resource "azurerm_resource_group" "main" {
  name     = "LongYearResearchPortal"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = "longyearresearchtf"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "reports"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "container"
}

resource "azurerm_service_plan" "main" {
  name                = "longyear-research-portal-sp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "main" {
  name                       = "longyear-research-portal-func"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  identity {
    type         = "SystemAssigned"
  }
  app_settings = {}
  site_config {
    application_stack {
      python_version = "3.9"
    }

    cors {
      allowed_origins = [ "*", ]
    }
  }
}

# Generate deploy script

resource "local_file" "deploy_azure_function" {
  filename = "scripts/deploy_function_app.sh"
  content  = <<-CONTENT
    zip -r build/function_app.zip \
    researchportal_func/function_app.py researchportal_func/host.json researchportal_func/requirements.txt \
    -x '*__pycache__*' \

   az functionapp deployment source config-zip \
    --resource-group ${azurerm_resource_group.main.name} \
    --name ${azurerm_linux_function_app.main.name} \
    --src build/function_app.zip \
    --build-remote true \
    --verbose
  CONTENT
}


resource "null_resource" "execfile" { 
    triggers = {
        always_run = timestamp()
    }
    provisioner "local-exec" { 
        command = "${path.module}/scripts/deploy_function_app.sh" 
        interpreter = ["/bin/bash"]
    }

    depends_on = [azurerm_linux_function_app.main, local_file.deploy_azure_function]
}


data "azurerm_function_app_host_keys" "main" {
  name                = azurerm_linux_function_app.main.name
  resource_group_name = azurerm_linux_function_app.main.resource_group_name

  depends_on = [azurerm_linux_function_app.main, null_resource.execfile]
}

# Export to github because we need this value in the frontend
resource "github_actions_secret" "function_url_all" {
  repository       = "LongYearFrontend"
  secret_name      = "RESEARCH_FUNCTION_URL_ALL_REPORTS"
  plaintext_value  = local.get_reports_url
}

# Export to github because we need this value in the frontend
resource "github_actions_secret" "function_url_one" {
  repository       = "LongYearFrontend"
  secret_name      = "RESEARCH_FUNCTION_URL_REPORT"
  plaintext_value  = local.get_report_url
}

# Frontend - Azure Static Web App
resource "azurerm_static_web_app" "main" {
  name                = "LongyearResearchPortalFrontend"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "github_actions_secret" "api_token" {
  repository       = "LongYearFrontend"
  secret_name      = "AZURE_STATIC_WEB_APPS_API_TOKEN"
  plaintext_value  = azurerm_static_web_app.main.api_key
}

# Key-vault
resource "azurerm_key_vault" "example" {
  name                        = "research-department-vault"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = azurerm_linux_function_app.main.tenant_id
    object_id = azurerm_linux_function_app.main.principal_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
  depends_on = [azurerm_linux_function_app.main]
}
/*
# Role assignment - Function app managed identity read key vault secrets
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key.primary.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.example.object_id
}
*/
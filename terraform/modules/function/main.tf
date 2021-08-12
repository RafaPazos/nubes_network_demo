
# This creates the plan that the service use
resource "azurerm_app_service_plan" "application" {
  name                = "plan-${var.application_name}-001"
  resource_group_name = var.resource_group
  location            = var.location

  kind     = "FunctionApp"
  reserved = true

  tags = {
    "environment" = var.environment
  }

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

locals {
  // A storage blob cannot contain hyphens, and is limited to 23 characters long
  storage-app-blob-name = substr(replace(var.application_name, "-", ""), 0, 16)
}

resource "azurerm_storage_account" "application" {
  name                      = "stapp${local.storage-app-blob-name}001"
  resource_group_name       = var.resource_group
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  allow_blob_public_access  = false

  tags = {
    "environment" = var.environment
  }
}

# This creates the service definition
resource "azurerm_function_app" "application" {
  name                       = "func-${var.application_name}-001"
  resource_group_name        = var.resource_group
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.application.id
  storage_account_name       = azurerm_storage_account.application.name
  storage_account_access_key = azurerm_storage_account.application.primary_access_key
  os_type                    = "linux"
  https_only                 = true
  version                    = "~3"

  tags = {
    "environment" = var.environment
  }

  site_config {
    linux_fx_version = "dotnet|3.1"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1"
    "FUNCTIONS_EXTENSION_VERSION" = "~3"
    "FUNCTIONS_WORKER_RUNTIME"    = "dotnet"

    # These are app specific environment variables
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "application" {
  key_vault_id   = var.vault_id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = azurerm_function_app.application.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Local variables for consistent naming
locals {
  resource_group_name      = "rg-${var.project_name}-${var.environment}"
  storage_account_name     = "st${var.project_name}${var.environment}"
  function_app_name        = "func-${var.project_name}-${var.environment}"
  service_plan_name        = "asp-${var.project_name}-${var.environment}"
  static_web_app_name      = "swa-${var.project_name}-${var.environment}"
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = substr(replace(local.storage_account_name, "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  # Security best practices
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true  # Required for Function App
  
  tags = local.common_tags
}

# App Service Plan (Consumption) for Function App
resource "azurerm_service_plan" "function_plan" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
  
  tags = local.common_tags
}

# Linux Function App
resource "azurerm_linux_function_app" "main" {
  name                       = local.function_app_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  https_only                 = true
  
  site_config {
    application_stack {
      node_version = "20"
    }
    
    cors {
      allowed_origins = [
        "https://${local.static_web_app_name}-*.azurestaticapps.net"
      ]
      support_credentials = false
    }
    
    application_insights_connection_string = azurerm_application_insights.main.connection_string
  }
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "node"
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "FUNCTIONS_EXTENSION_VERSION"    = "~4"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~20"
  }
  
  tags = local.common_tags
  
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  
  tags = local.common_tags
}

# Azure Static Web App
resource "azurerm_static_web_app" "main" {
  name                = local.static_web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = "westus2"  # SWA limited regions
  sku_tier            = "Free"
  sku_size            = "Free"
  
  tags = local.common_tags
}

# Link Function App to Static Web App
resource "azurerm_static_web_app_function_app_registration" "main" {
  static_web_app_id = azurerm_static_web_app.main.id
  function_app_id   = azurerm_linux_function_app.main.id
}

# Azure Container Registry for holding container images for app deployment in this environment
resource "azurerm_container_registry" "app_acr" {
  name                = "${var.acr_name}"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_container_registry_scope_map" "app_acr_token_scope" {
  name                    = "${var.environment}-Token-Scope"
  container_registry_name = azurerm_container_registry.app_acr.name
  resource_group_name     = azurerm_resource_group.app_rg.name
  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write"
  ]
}

resource "azurerm_container_registry_token" "app_acr_token" {
  name                    = "${var.environment}-Token"
  container_registry_name = azurerm_container_registry.app_acr.name
  resource_group_name     = azurerm_resource_group.app_rg.name
  scope_map_id            = azurerm_container_registry_scope_map.app_acr_token_scope.id
}

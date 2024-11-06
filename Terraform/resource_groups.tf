# Resource group to house application components
resource "azurerm_resource_group" "app_rg" {
  name     = "${var.environment}-app-rg"
  location = "West Europe"
  tags     = local.tags
}

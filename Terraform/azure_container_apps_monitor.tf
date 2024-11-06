# Configure a storage account and audit logging diagnostic settings for the given environment (could be done with LA workspace as well, though trying to limit cost)
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.environment}-log-analytics"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}


resource "azurerm_monitor_diagnostic_setting" "container_app_env_diagnostic" {
  name               = "${azurerm_container_app_environment.app_environment.name}-acadiagnostics"
  target_resource_id = azurerm_container_app_environment.app_environment.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  # Enable logs for monitoring
  enabled_log {
    category_group = "audit"
  }

}

resource "azurerm_monitor_metric_alert" "net_container_restarts" {
  name                = "${azurerm_container_app.net_app.name}-${var.environment}-container-restart-alert"
  resource_group_name = azurerm_resource_group.app_rg.name
  scopes              = [azurerm_container_app.net_app.id]
  description         = "Alert when container restarts exceed 5 in 15 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts_action_group.id
  }
}

resource "azurerm_monitor_metric_alert" "java_container_restarts" {
  name                = "${azurerm_container_app.java_app.name}-${var.environment}-container-restart-alert"
  resource_group_name = azurerm_resource_group.app_rg.name
  scopes              = [azurerm_container_app.java_app.id]
  description         = "Alert when container restarts exceed 5 in 15 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts_action_group.id
  }
}

# Setup an action group to be alerted in case of issues
resource "azurerm_monitor_action_group" "alerts_action_group" {
  name                = "${var.environment}-alerts"
  resource_group_name = azurerm_resource_group.app_rg.name
  short_name          = "${var.environment}-alerts"

  email_receiver {
    name          = "app_admin"
    email_address = "${var.alert_email}"
  }
}

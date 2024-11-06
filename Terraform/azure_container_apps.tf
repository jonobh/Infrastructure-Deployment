# App Environment to house Azure Container Applications
resource "azurerm_container_app_environment" "app_environment" {
  name                       = "${var.environment}BHAppEnvironment"
  location                   = azurerm_resource_group.app_rg.location
  resource_group_name        = azurerm_resource_group.app_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
  tags                       = local.tags
}

# User-Assigned Managed Identity - Allows container apps to pull images from Azure Container Registry
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "ContainerAppIdentity"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  tags                = local.tags
}

# Assign AcrPull Role to the Managed Identity, scoped to the afore created Azure Container Registry for this environment
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.app_acr.id
}

# Setup a container app for the .NET application. Use a dummy container image for now, as this application will be updated via the application build/deploy pipeline.
resource "azurerm_container_app" "net_app" {
  depends_on                   = [azurerm_user_assigned_identity.app_identity, azurerm_role_assignment.acr_pull]
  name                         = "netapplication"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"
  tags                         = local.tags
  template {
    min_replicas = 1
    max_replicas = 5
    
    container {
      name   = "netapplication"
      image  = "mcr.microsoft.com/dotnet/aspnet:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }

    http_scale_rule {
      name  = "trafficscalingrule"
      concurrent_requests = 100
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  registry {
    server   = "${var.acr_name}.azurecr.io"
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  ingress {
     allow_insecure_connections = true
     target_port = 80
     traffic_weight {
       percentage = 100
       latest_revision = true
     }
     external_enabled = true
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
 
}

# Setup a container app for the Java application. Use a dummy container image for now, as this application will be updated via the application build/deploy pipeline.
resource "azurerm_container_app" "java_app" {
  depends_on                   = [azurerm_user_assigned_identity.app_identity, azurerm_role_assignment.acr_pull]
  name                         = "javaapplication"
  container_app_environment_id = azurerm_container_app_environment.app_environment.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"
  tags                         = local.tags
  template {
    min_replicas = 1
    max_replicas = 5

    container {
      name   = "javaapplication"
      image  = "mcr.microsoft.com/dotnet/aspnet:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }

    http_scale_rule {
      name  = "trafficscalingrule"
      concurrent_requests = 100
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  registry {
    server   = "${var.acr_name}.azurecr.io"
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  ingress {
     allow_insecure_connections = true
     target_port = 8080
     traffic_weight {
      percentage = 100
      latest_revision = true
     }
     external_enabled = true
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
}

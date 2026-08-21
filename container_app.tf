resource "azurerm_log_analytics_workspace" "law" {
  name = "law01"
  location = azurerm_resource_group.arg.name
  resource_group_name = azurerm_resource_group.arg.location
  sku = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_container_app_environment" "conenv02" {
  name = "appenv02"
  location = azurerm_container_registry.acr.location
  resource_group_name = azurerm_resource_group.arg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app" "conapp01" {
  name = "containerapp-02"
  resource_group_name = azurerm_resource_group.arg.name
  container_app_environment_id = azurerm_container_app_environment.conenv02.id
  revision_mode = "Single"

  template {
    container {
      name = "container01"
      image = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu = 0.25
      memory = "0.5Gi"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  registry {
    server = azurerm_container_registry.acr.login_server
    identity = "SystemAssigned"
  }
}
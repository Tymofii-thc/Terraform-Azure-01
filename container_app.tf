# resource "azurerm_log_analytics_workspace" "law" {
#   name = "law01"
#   location = "francecentral"
#   resource_group_name = azurerm_resource_group.arg.name
#   sku = "PerGB2018"
#   retention_in_days = 30
# }

resource "azurerm_container_app_environment" "conenv02" {
  name                = "appenv02"
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name
  # logs_destination = "log-analytics"
  # log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app" "conapp01" {
  name                         = "containerapp-02"
  resource_group_name          = azurerm_resource_group.arg.name
  container_app_environment_id = azurerm_container_app_environment.conenv02.id
  revision_mode                = "Single"

  template {
    container {
      name   = "container01"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }

      env {
        name = "STORAGE_ACCOUNT_URL"
        value = azurerm_storage_account.storacc01.primary_blob_endpoint
      }

      env {
        name = "CONTAINER_NAME"
        value = azurerm_storage_container.photos01.name
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.app.id
  }
}




# resource "azurerm_role_assignment" "acr_pull" {
#   scope = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id = azurerm_container_app.conapp01.identity[0].principal_id
# }

resource "azurerm_user_assigned_identity" "app" {
  name = "uai_containerapp"
  resource_group_name = azurerm_resource_group.arg.name
  location = azurerm_resource_group.arg.location
}

resource "azurerm_role_assignment" "acr_pull" {
  scope = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "storage_cont" {
  scope = azurerm_storage_account.storacc01.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_user_assigned_identity.app.principal_id
}
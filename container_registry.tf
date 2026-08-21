resource "azurerm_container_registry" "acr" {
  name                = "conre02"
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name
  sku                 = "Basic"
}
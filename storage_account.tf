resource "azurerm_storage_account" "storacc01" {
  name                          = "storageforterraform01"
  resource_group_name           = azurerm_resource_group.arg.name
  location                      = azurerm_resource_group.arg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  shared_access_key_enabled     = true
  public_network_access_enabled = true
}
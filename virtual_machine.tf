resource "azurerm_resource_group" "arg" {
  name     = "rg-terraform-01"
  location = "Sweden Central"
}

resource "azurerm_virtual_network" "vnet-vm-01" {
  name                = "vnet-vm-01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name
}

resource "azurerm_subnet" "subnet-vm-01" {
  name                 = "subnet-vm-01"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet-vm-01.name
  resource_group_name  = azurerm_resource_group.arg.name
}

resource "azurerm_public_ip" "pip-vm-01" {
  name                = "pip-vm-01"
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm-net-ifc-01" {
  name                = "vm-net-interface-01"
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name

  ip_configuration {
    name                          = "ipconfig-01"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet-vm-01.id
    public_ip_address_id          = azurerm_public_ip.pip-vm-01.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-01" {
  name                  = "vm-01"
  location              = azurerm_resource_group.arg.location
  resource_group_name   = azurerm_resource_group.arg.name
  size                  = "Standard_B2ats_v2"
  admin_username        = "tymofii"
  network_interface_ids = [azurerm_network_interface.vm-net-ifc-01.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "tymofii"
    public_key = file("~/.ssh/Tymofii-vm-key.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-22_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-vm-01"
  location            = azurerm_resource_group.arg.location
  resource_group_name = azurerm_resource_group.arg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "212.180.187.162/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm-net-ifc-01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
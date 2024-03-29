provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "sqlserver-rg" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "sqlserver-vn" {
  name                = "${var.prefix}-VN"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.sqlserver-rg.location
  resource_group_name = azurerm_resource_group.sqlserver-rg.name
}

resource "azurerm_subnet" "sqlserver-sub" {
  name                 = "${var.prefix}-SN"
  resource_group_name  = azurerm_resource_group.sqlserver-rg.name
  virtual_network_name = azurerm_virtual_network.sqlserver-vn.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_network_security_group" "sqlserver-nsg" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.sqlserver-rg.location
  resource_group_name = azurerm_resource_group.sqlserver-rg.name
}

resource "azurerm_subnet_network_security_group_association" "sqlserver-snga" {
  subnet_id                 = azurerm_subnet.sqlserver-sub.id
  network_security_group_id = azurerm_network_security_group.sqlserver-nsg.id
}

resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-PIP"
  location            = azurerm_resource_group.sqlserver-rg.location
  resource_group_name = azurerm_resource_group.sqlserver-rg.name
  allocation_method   = "Dynamic"
}



resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "RDPRule"
  resource_group_name         = azurerm_resource_group.sqlserver-rg.name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.sqlserver-nsg.name
}

resource "azurerm_network_security_rule" "MSSQLRule" {
  name                        = "MSSQLRule"
  resource_group_name         = azurerm_resource_group.sqlserver-rg.name
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 1433
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.sqlserver-nsg.name
}

resource "azurerm_network_interface" "sqlserver-ni" {
  name                = "${var.prefix}-NIC"
  location            = azurerm_resource_group.sqlserver-rg.location
  resource_group_name = azurerm_resource_group.sqlserver-rg.name

  ip_configuration {
    name                          = "exampleconfiguration1"
    subnet_id                     = azurerm_subnet.sqlserver-sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "sqlserver" {
  network_interface_id      = azurerm_network_interface.sqlserver-ni.id
  network_security_group_id = azurerm_network_security_group.sqlserver.-nsg.id
}

resource "azurerm_linux_virtual_machine" "examsqlserverple" {
  name                  = "${var.prefix}-VM"
  location              = azurerm_resource_group.sqlserver-rg.location
  resource_group_name   = azurerm_resource_group.sqlserver-rg.name
  network_interface_ids = [azurerm_network_interface.sqlserver-ni.id]
  vm_size               = "Standard_DS14_v2"
  
  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-OSDisk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  custom_data = filebase64("./docker-composeDB.yml")

  os_profile {
    computer_name  = "winhost01"
    admin_username = "sa"
    admin_password = "mrpeer123#"
  }

}
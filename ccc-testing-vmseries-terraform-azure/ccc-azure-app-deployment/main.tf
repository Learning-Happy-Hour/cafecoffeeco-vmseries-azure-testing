# Generate a random password
resource "random_password" "this" {

  length           = 16
  min_lower        = 16 - 4
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "_%@"
}


locals {
  vm_password = coalesce(var.vm_password, try(random_password.this.result, null))
}

# Create or source the Resource Group
resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = "${var.name_prefix}${var.resource_group_name}"
  location = var.location

  tags = var.tags
}

data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.this[0] : data.azurerm_resource_group.this[0]
}

#The network required for the topology

resource "azurerm_virtual_network" "app-vnet" {
 
  name                = "${var.name_prefix}${var.vnet.name}"
  address_space       = var.vnet.address_space
  location               = var.location
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "app-subnet01" {

  name                 = var.subnets.app-subnet01.name
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.app-vnet.name
  address_prefixes     = var.subnets.app-subnet01.address_prefixes
}

resource "azurerm_network_security_group" "app-nsg" {
  
  name                = "app-nsg"
  location               = var.location
  resource_group_name = local.resource_group.name
  
  security_rule {
    name                       = "http-ssh-Inbound-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefixes    = ["0.0.0.0/0"]
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["22", "80"]
  }
}

resource "azurerm_subnet_network_security_group_association" "app-subnet01-nsg" {
   subnet_id                 = azurerm_subnet.app-subnet01.id
   network_security_group_id = azurerm_network_security_group.app-nsg.id
}


##CafeCoffeeCo Web-app server 

# Create network interface
resource "azurerm_network_interface" "app-nic" {
  name = "app-nic"
  location            = var.location
  resource_group_name = local.resource_group.name

  ip_configuration {
    name                          = "app-nic"
    subnet_id                     = azurerm_subnet.app-subnet01.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.112.1.4"
    #public_ip_address_id          = azurerm_public_ip.app-vm-public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  network_interface_id      = azurerm_network_interface.app-nic.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}

#deploying an Ubunutu vm

resource "azurerm_virtual_machine" "app-vm" {
  name = "app-vm"
  resource_group_name = local.resource_group.name
  location            = var.location
  vm_size             = "Standard_ds1_v2"
  network_interface_ids = [azurerm_network_interface.app-nic.id]

  storage_image_reference {
   
    publisher = var.custom_image_id
    offer     = var.img_offer
    sku       = var.img_sku
    version   = var.img_version
  }  
 storage_os_disk {
    name              = coalesce(var.os_disk_name, "app-vm-vhd")
    create_option     = "FromImage"
    caching              = "ReadWrite"
    os_type           = "Linux"
  }

delete_os_disk_on_termination    = true
delete_data_disks_on_termination = true

os_profile {
  admin_username      = "appadmin"
  admin_password = coalesce(var.vm_password, random_password.this.result)
  computer_name  = "ccc-web-app"
  custom_data    = file("ccc-user-data.sh")
  }

 os_profile_linux_config {
    disable_password_authentication = false
  }
}

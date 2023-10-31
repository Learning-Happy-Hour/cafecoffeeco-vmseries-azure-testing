# --- GENERAL --- #
location              = "Australia East"
resource_group_name   = "management-rg"
name_prefix           = "ccc-"
create_resource_group = true
panorama_sku = "byol"
tags = {
  "CreatedBy"   = "hadi zadeh"
  "CreatedWith" = "Terraform"
}
enable_zones = false


# --- VNET PART --- #
vnets = {
  "vnet" = {
    name          = "management-vnet"
    address_space = ["10.255.0.0/16"]
    network_security_groups = {
      "panorama" = {
        name = "panorama-nsg"
        rules = {
          vmseries_mgmt_allow_inbound = {
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_address_prefixes    = ["0.0.0.0/0"] 
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_ranges    = ["22", "443"]
          }
        }
      }
    }
    subnets = {
      "panorama" = {
        name                   = "panorama-subnet"
        address_prefixes       = ["10.255.0.0/24"]
        network_security_group = "panorama"
      }
    }
  }
}


panorama_version = "10.2.3"

panoramas = {
  "pn-1" = {
    name     = "panorama01"
    vnet_key = "vnet"
    interfaces = [
      {
        name               = "management"
        subnet_key         = "panorama"
        private_ip_address = "10.255.0.4"
        create_pip         = true
      },
    ]
  }
}

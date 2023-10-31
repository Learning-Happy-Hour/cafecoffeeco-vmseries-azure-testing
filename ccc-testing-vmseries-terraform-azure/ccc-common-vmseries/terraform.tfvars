# --- GENERAL --- #
location            = "Australia East"
resource_group_name = "transit-rg"
name_prefix         = "ccc-"
tags = {
  "CreatedBy"   = "hadi zadeh"
  "CreatedWith" = "Terraform"
}


# --- VNET PART --- #
vnets = {
  "transit" = {
    name          = "transit-vnet"
    address_space = ["10.110.0.0/16"]
    network_security_groups = {
      "management" = {
        name = "mgmt-nsg"
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
      "public" = {
        name = "public-nsg"
        rules = {
          vmseries_mgmt_allow_inbound = {
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_address_prefixes    = ["0.0.0.0/0"] 
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_ranges    = ["0-65535"]
          }
        }
      }
      "private" = {
        name = "private-nsg"
        rules = {
          vmseries_mgmt_allow_inbound = {
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_address_prefixes    = ["0.0.0.0/0"] 
            source_port_range          = "*"
            destination_address_prefix = "*"
            destination_port_ranges    = ["0-65535"]
          }
        }
      }
    }
    route_tables = {
      "management" = {
        name = "mgmt-rt"
        routes = {
          "private_blackhole" = {
            address_prefix = "10.110.0.0/24"
            next_hop_type  = "None"
          }
          "public_blackhole" = {
            address_prefix = "10.110.129.0/24"
            next_hop_type  = "None"
          }
        }
      }
      "public" = {
        name = "public-rt"
        routes = {
          "mgmt_blackhole" = {
            address_prefix = "10.110.255.0/24"
            next_hop_type  = "None"
          }
          "private_blackhole" = {
            address_prefix = "10.110.0.0/24"
            next_hop_type  = "None"
          }
        }
      }
     "private" = {
        name = "private-rt"
        routes = {
          "default" = {
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.110.0.21"
          }
          "mgmt_blackhole" = {
            address_prefix = "10.110.255.0/24"
            next_hop_type  = "None"
          }
          "public_blackhole" = {
            address_prefix = "10.110.129.0/24"
            next_hop_type  = "None"
          }
        }
      }
    }
    subnets = {
      "management" = {
        name                            = "mgmt-snet"
        address_prefixes                = ["10.110.255.0/24"]
        network_security_group          = "management"
        route_table                     = "management"
        enable_storage_service_endpoint = true
      }
      "public" = {
        name                   = "public-snet"
        address_prefixes       = ["10.110.129.0/24"]
        network_security_group = "public"
        route_table            = "public"
      }
      "private" = {
        name             = "private-snet"
        address_prefixes = ["10.110.0.0/24"]
        route_table      = "private"
      }
    }
  }
}


# --- LOAD BALANCING PART --- #
load_balancers = {
  "public" = {
    name                              = "public-lb"
    nsg_vnet_key                      = "transit"
    nsg_key                           = "public"
    network_security_allow_source_ips = ["0.0.0.0/0"] 
    avzones                           = ["1", "2", "3"]
    frontend_ips = {
      "palo-lb-app1" = {
        create_public_ip = true
        in_rules = {
          "balanceHttp" = {
            protocol = "Tcp"
            port     = 80
          }
        }
      }
    }
  }
  "private" = {
    name    = "private-lb"
    avzones = ["1", "2", "3"]
    frontend_ips = {
      "ha-ports" = {
        vnet_key           = "transit"
        subnet_key         = "private"
        private_ip_address = "10.110.0.21"
        in_rules = {
          HA_PORTS = {
            port     = 0
            protocol = "All"
          }
        }
      }
    }
  }
}


# --- VMSERIES PART --- #
vmseries_version = "10.2.3"
vmseries_vm_size = "Standard_DS3_v2"
vmseries = {
 "fw-1" = {
   name              = "firewall01"
   bootstrap_options = "type=dhcp-client;panorama-server=10.255.0.4;auth-key=;dgname=Azure Transit_DG;tplname=Azure Transit_TS;plugin-op-commands=panorama-licensing-mode-on;dhcp-accept-server-hostname=yes;dhcp-accept-server-domain=yes"
   vnet_key          = "transit"
   avzone            = 1
   interfaces = [
     {
       name       = "mgmt"
       subnet_key = "management"
       create_pip = true
     },
     
     {
       name              = "public"
       subnet_key        = "public"
       load_balancer_key = "public"
       create_pip        = true
     },
      {
       name              = "private"
       subnet_key        = "private"
       load_balancer_key = "private"
     },
   ]
 }
 "fw-2" = {
   name              = "firewall02"
   bootstrap_options = "type=dhcp-client;panorama-server=10.255.0.4;auth-key=;dgname=Azure Transit_DG;tplname=Azure Transit_TS;plugin-op-commands=panorama-licensing-mode-on;dhcp-accept-server-hostname=yes;dhcp-accept-server-domain=yes"
   vnet_key          = "transit"
   avzone            = 2
   interfaces = [
     {
       name       = "mgmt"
       subnet_key = "management"
       create_pip = true
     },
     {
       name              = "public"
       subnet_key        = "public"
       load_balancer_key = "public"
       create_pip        = true
     },
      {
       name              = "private"
       subnet_key        = "private"
       load_balancer_key = "private"
     },
   ]
 }
}

#vnet peering 
peer_vnets = {
  "management" = {
    "vnet_name" = "ccc-management-vnet"
    "resource_group_name" = "ccc-management-rg"
  }
  "app" = {
    "vnet_name" = "ccc-app01-vnet"
    "resource_group_name" = "ccc-app-rg"
  }
}

# Generate a random password.
resource "random_password" "this" {
  count = var.vmseries_password == null ? 1 : 0

  length           = 16
  min_lower        = 16 - 4
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "_%@"
}

locals {
  vmseries_password = coalesce(var.vmseries_password, try(random_password.this[0].result, null))
}

# Obtain Public IP address of code deployment machine

##data "http" "this" {
##  count = length(var.bootstrap_storage) > 0 && contains([for v in values(var.bootstrap_storage) : v.storage_acl], true) ? 1 : 0
##  url   = "https://ifconfig.me/ip"
##}

# Create or source the Resource Group.
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

# Manage the network required for the topology.
module "vnet" {
  source = "../modules/vnet"

  for_each = var.vnets

  name                   = each.value.name
  name_prefix            = var.name_prefix
  create_virtual_network = try(each.value.create_virtual_network, true)
  resource_group_name    = try(each.value.resource_group_name, local.resource_group.name)
  location               = var.location

  address_space = try(each.value.create_virtual_network, true) ? each.value.address_space : []

  create_subnets = try(each.value.create_subnets, true)
  subnets        = each.value.subnets

  network_security_groups = try(each.value.network_security_groups, {})
  route_tables            = try(each.value.route_tables, {})

  tags = var.tags
}


# create load balancers, both internal and external
module "load_balancer" {
  source = "../modules/loadbalancer"

  for_each = var.load_balancers

  name                = "${var.name_prefix}${each.value.name}"
  location            = var.location
  resource_group_name = local.resource_group.name
  enable_zones        = var.enable_zones
  avzones             = try(each.value.avzones, null)

  network_security_group_name = try(
    "${var.name_prefix}${var.vnets[each.value.nsg_vnet_key].network_security_groups[each.value.nsg_key].name}",
    each.value.network_security_group_name,
    null
  )
  # network_security_group_name          = try(each.value.network_security_group_name, null)
  network_security_resource_group_name = try(
    var.vnets[each.value.nsg_vnet_key].resource_group_name,
    each.value.network_security_group_rg_name,
    null
  )
  network_security_allow_source_ips = try(each.value.network_security_allow_source_ips, [])

  frontend_ips = {
    for k, v in each.value.frontend_ips : k => {
      create_public_ip         = try(v.create_public_ip, false)
      public_ip_name           = try(v.public_ip_name, null)
      public_ip_resource_group = try(v.public_ip_resource_group, null)
      private_ip_address       = try(v.private_ip_address, null)
      subnet_id                = try(module.vnet[v.vnet_key].subnet_ids[v.subnet_key], null)
      in_rules                 = try(v.in_rules, {})
      out_rules                = try(v.out_rules, {})
    }
  }

  tags       = var.tags
  depends_on = [module.vnet]
}




# create the actual VMSeries VMs and resources
module "ai" {
  source = "../modules/application_insights"

  for_each = toset(
    var.application_insights != null ? flatten(
      try([var.application_insights.name], [for _, v in var.vmseries : "${v.name}-ai"])
    ) : []
  )

  name                = "${var.name_prefix}${each.key}"
  resource_group_name = local.resource_group.name
  location            = var.location

  workspace_mode            = try(var.application_insights.workspace_mode, null)
  workspace_name            = try(var.application_insights.workspace_name, "${var.name_prefix}${each.key}-wrkspc")
  workspace_sku             = try(var.application_insights.workspace_sku, null)
  metrics_retention_in_days = try(var.application_insights.metrics_retention_in_days, null)

  tags = var.tags
}

resource "azurerm_availability_set" "this" {
  for_each = var.availability_sets

  name                         = "${var.name_prefix}${each.value.name}"
  resource_group_name          = local.resource_group.name
  location                     = var.location
  platform_update_domain_count = try(each.value.update_domain_count, null)
  platform_fault_domain_count  = try(each.value.fault_domain_count, null)

  tags = var.tags
}

module "vmseries" {
  source = "../modules/vmseries"

  for_each = var.vmseries

  location            = var.location
  resource_group_name = local.resource_group.name

  name        = "${var.name_prefix}${each.value.name}"
  username    = var.vmseries_username
  password    = local.vmseries_password
  img_version = try(each.value.version, var.vmseries_version)
  img_sku     = var.vmseries_sku
  vm_size     = try(each.value.vm_size, var.vmseries_vm_size)
  avset_id    = try(azurerm_availability_set.this[each.value.availability_set_key].id, null)

  enable_zones = var.enable_zones
  avzone       = try(each.value.avzone, 1)
  bootstrap_options = each.value.bootstrap_options


  interfaces = [for v in each.value.interfaces : {
    name                     = "${var.name_prefix}${each.value.name}-${v.name}"
    subnet_id                = try(module.vnet[each.value.vnet_key].subnet_ids[v.subnet_key], null)
    create_public_ip         = try(v.create_pip, false)
    public_ip_name           = try(v.public_ip_name, null)
    public_ip_resource_group = try(v.public_ip_resource_group, null)
    enable_backend_pool      = can(v.load_balancer_key) ? true : false
    lb_backend_pool_id       = try(module.load_balancer[v.load_balancer_key].backend_pool_id, null)
    private_ip_address       = try(v.private_ip_address, null)
  }]

  tags = var.tags
  depends_on = [
    module.vnet,
    azurerm_availability_set.this
  ]
}

## -- VNET peering and routing -- ##
 
module "peering" {
  source = "../modules/vnet_peering"

  for_each = var.peer_vnets

  local_peer_config = {
    vnet_name = "ccc-transit-vnet"
    resource_group_name = local.resource_group.name
  }
  remote_peer_config = {
    vnet_name = each.value.vnet_name
    resource_group_name = each.value.resource_group_name
  } 
  depends_on = [module.vnet, module.vmseries]
}

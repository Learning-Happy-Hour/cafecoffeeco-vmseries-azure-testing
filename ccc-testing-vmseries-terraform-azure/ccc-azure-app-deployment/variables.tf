### GENERAL
variable "tags" {
  description = "Map of tags to assign to the created resources."
  default     = {}
  type        = map(string)
}

variable "location" {
  description = "The Azure region to use."
  type        = string
}

variable "name_prefix" {
  description = <<-EOF
  A prefix that will be added to all created resources.
  There is no default delimiter applied between the prefix and the resource name. Please include the delimiter in the actual prefix.

  Example:
  ```
  name_prefix = "test-"
  ```
  
  NOTICE. This prefix is not applied to existing resources. If you plan to reuse i.e. a VNET please specify it's full name, even if it is also prefixed with the same value as the one in this property.
  EOF
  default     = ""
  type        = string
}

variable "create_resource_group" {
  description = <<-EOF
  When set to `true` it will cause a Resource Group creation. Name of the newly specified RG is controlled by `resource_group_name`.
  When set to `false` the `resource_group_name` parameter is used to specify a name of an existing Resource Group.
  EOF
  default     = true
  type        = bool
}

variable "resource_group_name" {
  description = "Name of the Resource Group to ."
  type        = string
}

variable "enable_zones" {
  description = "If `true`, enable zone support for resources."
  default     = true
  type        = bool
}

variable "vm_password" {
  description = "app vm password"
  default     = null
  type        = string
}

variable "custom_image_id" {
  description = "Absolute ID of your own Custom Image to be used for creating a new virtual machine. If set, the `username`, `password`, `img_version`, `img_publisher`, `img_offer`, `img_sku` inputs are all ignored (these are used only for published images, not custom ones)."
  default     = null
  type        = string
}

variable "img_publisher" {
  description = "The Azure Publisher identifier for a image which should be deployed."
  default     = null
  type        = string
}

variable "img_offer" {
  description = "The Azure Offer identifier corresponding to a published image."
  default     = null
  type        = string
}

variable "img_sku" {
  description = "Virtual machine image SKU - list available with `az vm image list -o table --all --publisher foo`"
  default     = null
  type        = string
}

variable "img_version" {
  description = "Virtual machine image version - list available for a default `img_offer` with `az vm image list -o table --publisher foo --offer bar --all`"
  default     = "latest"
  type        = string
}
variable "os_disk_name" {
  description = "Optional name of the OS disk to create for the virtual machine. If empty, the name is auto-generated."
  default     = null
  type        = string
}


### VNET
variable "vnet" {
 description = "vnet list"
  default     = {}
}

variable "network_security_groups" {
 description = "NSG list"
  default     = {}
}

variable "subnets"  {
      description = "subnet list"
  default     = {}
}


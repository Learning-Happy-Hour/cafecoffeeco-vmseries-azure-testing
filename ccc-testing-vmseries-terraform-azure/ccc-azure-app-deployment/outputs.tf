output "username" {
  description = "Initial administrative username to use for VM-Series."
  value       = "appadmin"
}

output "password" {
  description = "Initial administrative password to use for VM-Series."
  value       = local.vm_password
  sensitive   = true
}

output "app_private_ip" {
  value = azurerm_network_interface.app-nic.private_ip_address
}


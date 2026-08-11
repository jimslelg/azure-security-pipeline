output "vnet_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "Subnet ID for AKS node pools."
  value       = azurerm_subnet.aks.id
}

output "private_endpoint_subnet_id" {
  description = "Subnet ID dedicated to private endpoints."
  value       = azurerm_subnet.private_endpoints.id
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone name => ID."
  value       = { for k, z in azurerm_private_dns_zone.zones : k => z.id }
}

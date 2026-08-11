# Network foundation. Two subnets: one for AKS nodes, one dedicated to
# private endpoints so PaaS data planes (Key Vault, ACR) are reachable only
# from inside the VNet.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 4, 0)]

  # Private endpoint policies stay enabled so NSGs apply to PE traffic too.
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 4, 1)]

  private_endpoint_network_policies = "Enabled"
}

# Default-deny inbound from internet on the AKS subnet. Intra-VNet and Azure
# LoadBalancer traffic keep working via the built-in allow rules; anything
# published externally must go through an explicit ingress with its own rules.
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${var.name_prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "deny-inbound-internet"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Private DNS zones so private-endpoint FQDNs resolve inside the VNet.
resource "azurerm_private_dns_zone" "zones" {
  for_each = toset([
    "privatelink.vaultcore.azure.net", # Key Vault
    "privatelink.azurecr.io",          # Container Registry
  ])

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "zones" {
  for_each = azurerm_private_dns_zone.zones

  name                  = "link-${var.name_prefix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = var.tags
}

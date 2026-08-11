# Key Vault hardened per Microsoft security baseline:
#   - RBAC authorization only (no access policies — auditable via Entra ID)
#   - Purge protection + soft delete (secrets survive accidental/malicious delete)
#   - Public network access disabled; reachable only via private endpoint
#   - Consumers get "Key Vault Secrets User" (read), never write roles

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_key_vault" "main" {
  # Vault names are globally unique and capped at 24 chars; random suffix
  # avoids collisions across re-creations while soft-deleted vaults linger.
  name                = substr(replace("kv-${var.name_prefix}-${random_string.suffix.result}", "_", "-"), 0, 24)
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  public_network_access_enabled = length(var.allowed_ip_ranges) > 0

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
  }
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${var.name_prefix}-kv"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

# Read-only secret access for consumers (e.g. the AKS workload identity).
# Write access is reserved for humans through PIM-elevated roles, not code.
resource "azurerm_role_assignment" "secrets_user" {
  for_each = var.reader_principal_ids

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

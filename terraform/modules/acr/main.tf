# Container registry hardening:
#   - Admin account disabled — no static username/password exists at all;
#     push happens via the pipeline's federated identity (AcrPush),
#     pull via the AKS kubelet identity (AcrPull).
#   - Anonymous pull disabled, export disabled (images can't be copied out
#     to another registry with a data-plane call).
#   - Premium SKU: required for private endpoints, quarantine, and
#     retention policies.
#   - Retention policy trims untagged manifests so vulnerable stale layers
#     don't accumulate.

resource "azurerm_container_registry" "main" {
  # Registry names: alphanumeric only, globally unique.
  name                = "acr${var.project}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  tags                = var.tags

  admin_enabled                 = false
  anonymous_pull_enabled        = false
  export_policy_enabled         = false
  public_network_access_enabled = length(var.allowed_ip_ranges) > 0
  zone_redundancy_enabled       = var.environment == "prod"

  dynamic "network_rule_set" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      dynamic "ip_rule" {
        for_each = var.allowed_ip_ranges
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  retention_policy_in_days = 14
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${var.name_prefix}-acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
}

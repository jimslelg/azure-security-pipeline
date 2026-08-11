# Managed identities. Two distinct identities with distinct blast radii:
#
#   1. workload  — assumed by application pods via AKS workload identity
#                  federation. Gets read-only access to Key Vault secrets and
#                  nothing else.
#   2. deployer  — federated to the Azure DevOps service connection (OIDC).
#                  Exists so the pipeline authenticates with short-lived
#                  tokens instead of a client secret. Role assignments for it
#                  are applied at subscription scope out-of-band (least
#                  privilege: Contributor on the platform RG only).
#
# Neither identity has a password, certificate, or exportable credential.

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name_prefix}-workload"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "deployer" {
  name                = "id-${var.name_prefix}-deployer"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Trust the Azure DevOps organization's OIDC issuer. Tokens are only accepted
# when issued for this exact service connection (subject claim), so another
# pipeline in the same org cannot borrow this identity.
resource "azurerm_federated_identity_credential" "ado" {
  count = var.ado_issuer_url != null ? 1 : 0

  name                = "fic-${var.name_prefix}-ado"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.deployer.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.ado_issuer_url
  subject             = var.ado_subject
}

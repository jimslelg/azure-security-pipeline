# Remote state in Azure Storage. Values are injected per environment by the
# pipeline (-backend-config), never hardcoded, so the same code serves dev/prod.
#
# The state storage account itself is expected to be hardened out-of-band:
#   - Entra ID auth only (use_azuread_auth), shared keys disabled
#   - Blob versioning + soft delete (state history / ransomware recovery)
#   - Network rules restricting access to the build agents
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}

output "id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.main.name
}

output "vault_uri" {
  description = "Vault URI used by the Secrets Store CSI driver."
  value       = azurerm_key_vault.main.vault_uri
}

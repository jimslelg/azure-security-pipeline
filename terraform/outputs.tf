output "resource_group_name" {
  description = "Name of the resource group holding all platform resources."
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name — used by the deploy stage for kubelogin."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for federating Kubernetes workload identities."
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "Registry login server; images are pushed here by the build stage."
  value       = module.acr.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI consumed by the Secrets Store CSI driver."
  value       = module.keyvault.vault_uri
}

output "workload_identity_client_id" {
  description = "Client ID of the user-assigned identity the app pods federate to."
  value       = module.identity.workload_identity_client_id
}

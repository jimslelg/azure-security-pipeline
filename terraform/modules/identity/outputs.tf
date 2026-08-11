output "workload_identity_id" {
  description = "Resource ID of the workload (pod) identity."
  value       = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_client_id" {
  description = "Client ID the pods present when federating."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID used for RBAC role assignments."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "deployer_identity_client_id" {
  description = "Client ID for the ADO service connection (workload identity federation)."
  value       = azurerm_user_assigned_identity.deployer.client_id
}

output "deployer_identity_principal_id" {
  description = "Principal ID of the deployer identity."
  value       = azurerm_user_assigned_identity.deployer.principal_id
}

# AKS hardening applied here:
#   - Entra ID integration with Azure RBAC; Kubernetes local accounts
#     DISABLED — there is no static admin kubeconfig to steal.
#   - Workload identity + OIDC issuer: pods federate to managed identities,
#     no secrets mounted for cloud auth.
#   - Azure Policy add-on: in-cluster admission control (privileged pods,
#     host mounts, untrusted registries are rejected at admit time).
#   - Azure CNI + Calico network policy so per-pod NetworkPolicies enforce.
#   - Defender for Containers profile enabled for runtime threat detection.
#   - API server access restricted to authorized CIDRs.
#   - Automatic patch upgrades + maintenance window.

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.name_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  local_account_disabled            = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  role_based_access_control_enabled = true

  automatic_upgrade_channel = "patch"

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ranges
  }

  default_node_pool {
    name                 = "system"
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    vnet_subnet_id       = var.subnet_id
    os_disk_type         = "Ephemeral"
    max_pods             = 50
    auto_scaling_enabled = false

    upgrade_settings {
      max_surge = "33%"
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    outbound_type  = "loadBalancer"
  }

  identity {
    type = "SystemAssigned"
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [kubernetes_version] # patch upgrades are automatic
  }
}

# Audit trail: control-plane logs (audit, API) retained in Log Analytics.
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "log-${var.name_prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${var.name_prefix}-aks"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard" # Entra ID authN/authZ decisions
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Kubelet pulls images with its managed identity — no imagePullSecrets in
# cluster, nothing to rotate or leak.
resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

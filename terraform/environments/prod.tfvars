environment        = "prod"
location           = "canadacentral"
aks_node_count     = 3
aks_node_vm_size   = "Standard_D4s_v5"
kubernetes_version = "1.31"

# Prod: no public data-plane access at all — private endpoints only.
allowed_ip_ranges = []

aks_admin_group_object_ids = [] # set to the break-glass Entra group in real use

tags = {
  cost_center = "production"
  criticality = "high"
}

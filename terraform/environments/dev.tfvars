environment        = "dev"
location           = "canadacentral"
aks_node_count     = 2
aks_node_vm_size   = "Standard_D2s_v5"
kubernetes_version = "1.31"

# Dev keeps PaaS firewalls open to the corporate egress range so engineers
# can iterate; prod (see prod.tfvars) is private-endpoint only.
allowed_ip_ranges = []

aks_admin_group_object_ids = [] # set to the platform-team Entra group in real use

tags = {
  cost_center = "engineering"
}

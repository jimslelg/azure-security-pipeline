locals {
  name_prefix = "${var.project}-${var.environment}"

  # Mandatory tags — enforced by Azure Policy (modules/policy). Anything
  # deployed outside this pipeline without them is flagged non-compliant.
  tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      repo        = "jimslelg/azure-security-pipeline"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}

module "identity" {
  source = "./modules/identity"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allowed_ip_ranges   = var.allowed_ip_ranges
  pe_subnet_id        = module.network.private_endpoint_subnet_id
  reader_principal_ids = {
    workload = module.identity.workload_identity_principal_id
  }
  tags = local.tags
}

module "acr" {
  source = "./modules/acr"

  name_prefix         = local.name_prefix
  project             = var.project
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allowed_ip_ranges   = var.allowed_ip_ranges
  pe_subnet_id        = module.network.private_endpoint_subnet_id
  tags                = local.tags
}

module "aks" {
  source = "./modules/aks"

  name_prefix            = local.name_prefix
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  kubernetes_version     = var.kubernetes_version
  node_count             = var.aks_node_count
  node_vm_size           = var.aks_node_vm_size
  subnet_id              = module.network.aks_subnet_id
  admin_group_object_ids = var.aks_admin_group_object_ids
  acr_id                 = module.acr.id
  workload_identity_id   = module.identity.workload_identity_id
  tags                   = local.tags
}

module "policy" {
  source = "./modules/policy"

  name_prefix       = local.name_prefix
  resource_group_id = azurerm_resource_group.main.id
  location          = var.location
  required_tag_keys = ["project", "environment", "managed_by"]
}

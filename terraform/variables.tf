variable "project" {
  description = "Short project slug used as a prefix for resource names."
  type        = string
  default     = "azsecpipe"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "canadacentral"
}

variable "aks_admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster-admin on AKS. Access is group-based, never user-based."
  type        = list(string)
  default     = []
}

variable "aks_node_count" {
  description = "Node count for the default AKS node pool."
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for the default AKS node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version (minor); patch upgrades are automatic."
  type        = string
  default     = "1.31"
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges allowed through Key Vault / ACR network ACLs (e.g. build agent egress IPs). Default deny."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags merged onto the mandatory tag set."
  type        = map(string)
  default     = {}
}

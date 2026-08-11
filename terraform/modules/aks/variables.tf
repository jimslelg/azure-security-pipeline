variable "name_prefix" {
  description = "Prefix for resource names (project-environment)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version."
  type        = string
}

variable "node_count" {
  description = "Default node pool size."
  type        = number
}

variable "node_vm_size" {
  description = "Default node pool VM size."
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the node pool."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Entra ID groups granted cluster admin."
  type        = list(string)
}

variable "api_server_authorized_ranges" {
  description = "CIDRs allowed to reach the API server. Empty list keeps it open — set this in every real environment."
  type        = list(string)
  default     = []
}

variable "acr_id" {
  description = "Registry ID the kubelet identity gets AcrPull on."
  type        = string
}

variable "workload_identity_id" {
  description = "User-assigned identity resource ID that application pods federate to (documented linkage; federation itself is configured per-namespace in Phase 5)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

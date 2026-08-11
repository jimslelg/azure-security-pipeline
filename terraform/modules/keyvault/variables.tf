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

variable "allowed_ip_ranges" {
  description = "CIDRs allowed through the vault firewall (build agents). Empty list = private endpoint only."
  type        = list(string)
  default     = []
}

variable "pe_subnet_id" {
  description = "Subnet for the vault's private endpoint."
  type        = string
}

variable "reader_principal_ids" {
  description = "Map of label => principal ID granted Key Vault Secrets User (read-only)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

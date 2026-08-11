variable "name_prefix" {
  description = "Prefix for resource names (project-environment)."
  type        = string
}

variable "project" {
  description = "Project slug (alphanumeric) for the registry name."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/prod)."
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
  description = "CIDRs allowed through the registry firewall (build agents). Empty = private endpoint only."
  type        = list(string)
  default     = []
}

variable "pe_subnet_id" {
  description = "Subnet for the registry's private endpoint."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

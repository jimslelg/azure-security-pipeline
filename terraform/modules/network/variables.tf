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

variable "address_space" {
  description = "VNet address space; subnets are carved from it with cidrsubnet."
  type        = string
  default     = "10.100.0.0/16"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

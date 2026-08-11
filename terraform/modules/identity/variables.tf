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

variable "ado_issuer_url" {
  description = "OIDC issuer URL of the Azure DevOps organization (vstoken.dev.azure.com/...). Null skips the federated credential."
  type        = string
  default     = null
}

variable "ado_subject" {
  description = "Subject claim of the ADO service connection, e.g. sc://org/project/connection-name."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

variable "name_prefix" {
  description = "Prefix for resource names (project-environment)."
  type        = string
}

variable "resource_group_id" {
  description = "Scope for the policy assignments."
  type        = string
}

variable "location" {
  description = "Azure region (required for assignments with managed identities; reserved for future modify/deploy effects)."
  type        = string
}

variable "required_tag_keys" {
  description = "Tag keys every resource must carry."
  type        = list(string)
  default     = ["project", "environment", "managed_by"]
}

output "assignment_ids" {
  description = "IDs of all guardrail policy assignments — the Phase 3 compliance gate queries these."
  value = concat(
    [for a in azurerm_resource_group_policy_assignment.guardrails : a.id],
    [for a in azurerm_resource_group_policy_assignment.required_tags : a.id],
  )
}

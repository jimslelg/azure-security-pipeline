# Azure Policy assignments — guardrails that hold even for changes made
# OUTSIDE this pipeline (portal clicks, az cli). The pipeline's Checkov scan
# is preventive at plan time; these are the enforcement backstop at the
# platform. Phase 3's pipeline additionally queries compliance state and
# fails the run if any assignment reports non-compliant resources.
#
# All definitions referenced are Azure built-ins (IDs are stable GUIDs).

locals {
  builtin = "/providers/Microsoft.Authorization/policyDefinitions"

  assignments = {
    # Deny privileged containers in the cluster (enforced by the AKS
    # Azure Policy add-on via Gatekeeper).
    no-privileged-containers = {
      definition   = "${local.builtin}/95edb821-ddaf-4404-9732-666045e056b4"
      display_name = "AKS: privileged containers are not allowed"
      effect       = "deny"
      parameters   = {}
    }

    # Deny containers escalating to root.
    no-privilege-escalation = {
      definition   = "${local.builtin}/1c6e92c9-99f0-4e55-9cf2-0c234dc48f99"
      display_name = "AKS: privilege escalation is not allowed"
      effect       = "deny"
      parameters   = {}
    }

    # Only allow images from trusted registries (our ACR + MCR for addons).
    allowed-registries = {
      definition   = "${local.builtin}/febd0533-8e55-448f-b837-bd0e06f16469"
      display_name = "AKS: images must come from allowed registries"
      effect       = "deny"
      parameters = {
        allowedContainerImagesRegex = {
          value = "^(acr[a-z0-9]+\\.azurecr\\.io|mcr\\.microsoft\\.com)/.*$"
        }
      }
    }

    # Key Vaults must have purge protection (audit — deny would block
    # legitimate legacy vaults in shared subscriptions).
    kv-purge-protection = {
      definition   = "${local.builtin}/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
      display_name = "Key Vault: purge protection must be enabled"
      effect       = "audit"
      parameters   = {}
    }

    # Storage accounts must disable public blob access.
    storage-no-public-blob = {
      definition   = "${local.builtin}/4fa4b6c0-31ca-4c0d-b10d-24b96f62a751"
      display_name = "Storage: public blob access is not allowed"
      effect       = "audit"
      parameters   = {}
    }
  }
}

resource "azurerm_resource_group_policy_assignment" "guardrails" {
  for_each = local.assignments

  name                 = each.key
  display_name         = each.value.display_name
  resource_group_id    = var.resource_group_id
  policy_definition_id = each.value.definition
  enforce              = each.value.effect == "deny"

  parameters = jsonencode(
    merge(each.value.parameters, { effect = { value = each.value.effect } })
  )
}

# Mandatory tags: resources missing them are flagged non-compliant, which the
# Phase 3 compliance gate surfaces on every run.
resource "azurerm_resource_group_policy_assignment" "required_tags" {
  for_each = toset(var.required_tag_keys)

  name                 = "require-tag-${each.value}"
  display_name         = "Tagging: '${each.value}' tag is required"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "${local.builtin}/871b6d14-10aa-478d-b590-94f262ecfa99"
  enforce              = false # audit-only; CI is the enforcement point

  parameters = jsonencode({
    tagName = { value = each.value }
  })
}

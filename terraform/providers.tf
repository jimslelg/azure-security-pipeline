terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Never bypass soft-delete during destroy — deleted secrets stay recoverable.
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      # Fail the destroy if the RG still contains resources Terraform doesn't know about.
      prevent_deletion_if_contains_resources = true
    }
  }

  # Authentication is intentionally NOT configured here. The pipeline signs in
  # via workload identity federation (OIDC) — no client secrets exist to leak.
  storage_use_azuread = true
}

tflint {
  required_version = ">= 0.50"
}

config {
  format = "compact"
  call_module_type = "local" # lint module code as called from the root
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Naming discipline supports auditability: unnamed/misnamed resources are
# harder to attribute during incident response.
rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

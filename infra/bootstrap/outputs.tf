output "state_resource_group_name" {
  description = "Resource group containing the Terraform state storage account."
  value       = azurerm_resource_group.state.name
}

output "state_storage_account_name" {
  description = "Storage account used for Terraform remote state."
  value       = azurerm_storage_account.state.name
}

output "state_container_name" {
  description = "Blob container used for Terraform remote state."
  value       = azurerm_storage_container.tfstate.name
}

output "core_backend_config" {
  description = "Backend configuration values for the core Terraform layer."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "core.dev.tfstate"
  }
}

output "aks_backend_config" {
  description = "Backend configuration values for the AKS Terraform layer."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "aks.dev.tfstate"
  }
}

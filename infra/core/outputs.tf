output "resource_group_name" {
  description = "Name of the core platform resource group."
  value       = azurerm_resource_group.core.name
}

output "location" {
  description = "Azure region used by the core platform."
  value       = azurerm_resource_group.core.location
}

output "vnet_id" {
  description = "ID of the platform virtual network."
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "ID of the subnet where AKS nodes will run."
  value       = azurerm_subnet.aks.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = azurerm_container_registry.main.login_server
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault."
  value       = azurerm_key_vault.main.id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.main.id
}

output "workload_identity_client_id" {
  description = "Client ID of the user-assigned managed identity used by the application workload."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity used by the application workload."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "workload_identity_id" {
  description = "Resource ID of the user-assigned managed identity used by the application workload."
  value       = azurerm_user_assigned_identity.workload.id
}

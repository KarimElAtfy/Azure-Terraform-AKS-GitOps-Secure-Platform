output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  description = "Resource group containing the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.resource_group_name
}

output "node_resource_group" {
  description = "Resource group managed by AKS for node resources."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by AKS Workload Identity."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity."
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "workload_identity_subject" {
  description = "Kubernetes subject federated with the Azure Managed Identity."
  value       = local.workload_identity_subject
}

output "get_credentials_command" {
  description = "Command used to download kubeconfig for this AKS cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.main.resource_group_name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}

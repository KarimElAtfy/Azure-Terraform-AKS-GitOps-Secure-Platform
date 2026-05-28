variable "environment" {
  description = "Environment name used for AKS naming and tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used for readable AKS resource names."
  type        = string
  default     = "aks-gitops-secure"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aks-gitops-secure-dev-gwc"
}

variable "dns_prefix" {
  description = "DNS prefix used by the AKS cluster."
  type        = string
  default     = "aks-gitops-secure-dev-gwc"
}

variable "node_resource_group_name" {
  description = "Name of the resource group automatically used by AKS for node resources."
  type        = string
  default     = "rg-aks-gitops-secure-nodes-dev-gwc"
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version. Leave null to let AKS pick the default supported version."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the default system node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size used by the AKS system node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR. Must not overlap with the VNet address space."
  type        = string
  default     = "10.41.0.0/16"
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP. Must be inside service_cidr."
  type        = string
  default     = "10.41.0.10"
}

variable "app_namespace" {
  description = "Kubernetes namespace used by the application workload."
  type        = string
  default     = "devsecops-api"
}

variable "app_service_account_name" {
  description = "Kubernetes ServiceAccount name federated with the Azure Managed Identity."
  type        = string
  default     = "devsecops-api"
}

variable "core_state_resource_group_name" {
  description = "Resource group containing the Terraform remote state storage account."
  type        = string
}

variable "core_state_storage_account_name" {
  description = "Storage account containing the core Terraform state."
  type        = string
}

variable "core_state_container_name" {
  description = "Blob container containing the core Terraform state."
  type        = string
  default     = "tfstate"
}

variable "core_state_key" {
  description = "Blob key for the core Terraform state file."
  type        = string
  default     = "core.dev.tfstate"
}

variable "tags" {
  description = "Common tags applied to AKS resources."
  type        = map(string)
  default = {
    project     = "aks-gitops-secure-platform"
    environment = "dev"
    managed_by  = "terraform"
    layer       = "aks"
  }
}

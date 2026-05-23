variable "location" {
  description = "Azure region used for the core platform resources."
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Environment name used for naming and tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used for tags and readable resource names."
  type        = string
  default     = "aks-gitops-secure"
}

variable "resource_group_name" {
  description = "Name of the main resource group for the platform."
  type        = string
  default     = "rg-aks-gitops-secure-dev-gwc"
}

variable "name_suffix" {
  description = "Optional lowercase suffix for globally unique resource names. If empty, Terraform generates one."
  type        = string
  default     = ""

  validation {
    condition     = var.name_suffix == "" || can(regex("^[a-z0-9]{4,8}$", var.name_suffix))
    error_message = "name_suffix must be empty or 4-8 lowercase alphanumeric characters."
  }
}

variable "vnet_address_space" {
  description = "Address space used by the platform virtual network."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes used by the AKS subnet."
  type        = list(string)
  default     = ["10.40.1.0/24"]
}

variable "acr_sku" {
  description = "SKU used for Azure Container Registry."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard, or Premium."
  }
}

variable "log_analytics_sku" {
  description = "SKU used for Log Analytics Workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Retention period for Log Analytics data."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags applied to core resources."
  type        = map(string)
  default = {
    project     = "aks-gitops-secure-platform"
    environment = "dev"
    managed_by  = "terraform"
    layer       = "core"
  }
}

variable "location" {
  description = "Azure region used for the Terraform state resources."
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Environment name used for tagging and naming."
  type        = string
  default     = "dev"
}

variable "state_resource_group_name" {
  description = "Name of the resource group that stores Terraform remote state."
  type        = string
  default     = "rg-aks-gitops-tfstate-dev-gwc"
}

variable "state_storage_account_prefix" {
  description = "Lowercase prefix for the globally unique Terraform state storage account name."
  type        = string
  default     = "staksgitopstf"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.state_storage_account_prefix)) && length(var.state_storage_account_prefix) >= 3 && length(var.state_storage_account_prefix) <= 18
    error_message = "The storage account prefix must be lowercase alphanumeric and between 3 and 18 characters."
  }
}

variable "state_container_name" {
  description = "Blob container name used to store Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Common tags applied to bootstrap resources."
  type        = map(string)
  default = {
    project     = "aks-gitops-secure-platform"
    environment = "dev"
    managed_by  = "terraform"
    layer       = "bootstrap"
  }
}

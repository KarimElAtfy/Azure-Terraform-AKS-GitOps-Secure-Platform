resource "random_string" "suffix" {
  count = var.name_suffix == "" ? 1 : 0

  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  suffix = var.name_suffix != "" ? var.name_suffix : random_string.suffix[0].result

  compact_location = "gwc"

  acr_name       = lower(substr("acr${replace(var.project_name, "-", "")}${local.suffix}", 0, 50))
  key_vault_name = lower(substr("kv-${var.project_name}-${local.suffix}", 0, 24))

  common_tags = merge(
    var.tags,
    {
      region = var.location
    }
  )
}

resource "azurerm_resource_group" "core" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}-${local.compact_location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-${var.project_name}-${var.environment}-${local.compact_location}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.aks_subnet_address_prefixes
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.core.name
  location            = azurerm_resource_group.core.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = local.common_tags
}

resource "azurerm_key_vault" "main" {
  name                       = local.key_vault_name
  location                   = azurerm_resource_group.core.location
  resource_group_name        = azurerm_resource_group.core.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.common_tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}-${local.compact_location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "mi-${var.project_name}-workload-${var.environment}-${local.compact_location}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  tags                = local.common_tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "current_user_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "workload_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

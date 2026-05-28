data "terraform_remote_state" "core" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.core_state_resource_group_name
    storage_account_name = var.core_state_storage_account_name
    container_name       = var.core_state_container_name
    key                  = var.core_state_key
  }
}

locals {
  common_tags = merge(
    var.tags,
    {
      region = data.terraform_remote_state.core.outputs.location
    }
  )

  workload_identity_subject = "system:serviceaccount:${var.app_namespace}:${var.app_service_account_name}"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = data.terraform_remote_state.core.outputs.location
  resource_group_name = data.terraform_remote_state.core.outputs.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version      = var.kubernetes_version
  node_resource_group     = var.node_resource_group_name
  sku_tier                = "Free"
  private_cluster_enabled = false

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = data.terraform_remote_state.core.outputs.aks_subnet_id

    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    outbound_type  = "loadBalancer"

    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = data.terraform_remote_state.core.outputs.log_analytics_workspace_id
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.terraform_remote_state.core.outputs.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

resource "azurerm_federated_identity_credential" "workload" {
  name                      = "fic-devsecops-api-${var.environment}"
  user_assigned_identity_id = data.terraform_remote_state.core.outputs.workload_identity_id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = local.workload_identity_subject
}


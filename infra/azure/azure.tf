variable "subscription_id" {
  default = ""
}
variable "tenant_id" {
  default = ""
}
variable "client_id" {
  default = ""
}
variable "client_secret" {
  default = ""
}
variable "prefix" {
  default = "fortosi"
}
variable "environment" {
  default = ""
}
variable "location" {
  default = ""
}
variable "vm_size" {
  default = "Standard_B2s"
}
variable "vm_count" {
  type    = number
  default = 1
}


terraform {
  required_version = ">= 0.13.3"
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  version         = "= 2.29.0"
  features {}
}


resource "azurerm_resource_group" "rg01" {
  name     = "${var.prefix}-${var.environment}-rg01"
  location = var.location

  tags = {
    managedby = "terraform"
  }
}

resource "azurerm_kubernetes_cluster" "aks01" {
  name                = "${var.prefix}-${var.environment}-aks01"
  resource_group_name = azurerm_resource_group.rg01.name
  location            = azurerm_resource_group.rg01.location
  dns_prefix          = "${var.prefix}-${var.environment}-aks01"
  kubernetes_version  = "1.17.11"

  default_node_pool {
    name       = "default"
    node_count = var.vm_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }
  }

  tags = {
    managedby = "terraform"
  }
}

resource "azurerm_role_assignment" "ra01" {
  scope                = azurerm_managed_disk.md01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks01.identity[0].principal_id
}

resource "azurerm_role_assignment" "ra02" {
  scope                = azurerm_storage_account.sa01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks01.identity[0].principal_id
}

resource "azurerm_managed_disk" "md01" {
  name                 = "${var.prefix}-${var.environment}-md01"
  resource_group_name  = azurerm_resource_group.rg01.name
  location             = azurerm_resource_group.rg01.location
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "32"

  tags = {
    managedby = "terraform"
  }
}

resource "azurerm_storage_account" "sa01" {
  name                     = "${var.prefix}${var.environment}sa01"
  resource_group_name      = azurerm_resource_group.rg01.name
  location                 = azurerm_resource_group.rg01.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    managedby = "terraform"
  }
}

resource "azurerm_storage_share" "ss01" {
  name                 = "deployment-kubeconfig"
  storage_account_name = azurerm_storage_account.sa01.name
  quota                = 1
}
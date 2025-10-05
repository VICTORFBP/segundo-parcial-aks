terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

# Variables
variable "rg_name"  { default = "parcial-aks-rg-scus" }
variable "location" { default = "southcentralus" }
variable "aks_name" { default = "parcial-aks" }
variable "acr_name" { default = "parcialacr20866" } # el ACR que ya está en southcentralus
variable "acr_rg"   { default = "parcial-aks-rg" } # ojo, el ACR está en el RG original


# Resource Group (ya creado, pero Terraform debe conocerlo)
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

# ACR (ya creado fuera, solo lo importamos como data)
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_rg
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "parcialdns"

  default_node_pool {
    name       = "systempool"
    node_count = 2
    vm_size    = "Standard_B2pls_v2" # cámbialo si tu región no lo soporta
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  # Habilitamos RBAC
  role_based_access_control_enabled = true
}

# Dar permisos al AKS para usar ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.acr.id
}

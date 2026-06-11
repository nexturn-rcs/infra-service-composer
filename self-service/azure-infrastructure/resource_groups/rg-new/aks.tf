provider "azurerm" {
  features = {}
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "otis-demo-demo-service-creation-aks-aks"
  location            = var.location
  resource_group_name = var.resource_group_name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project = var.project_name
    service = var.service_name
    tech    = var.tech_stack
  }
}

output "aks_cluster_name" {
  description = "AKS cluster name (if created)"
  value       = azurerm_kubernetes_cluster.aks.name
}

  provider "azurerm" {
  features = {}
  }
  
  resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myproject-myservice-aks"
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
  EOF

  cat >> "demo1-rg-selfservice/outputs.tf" <<'EOF'
  output "aks_cluster_name" {
  description = "AKS cluster name (if created)" 
  value       = azurerm_kubernetes_cluster.aks.name
  }
  EOF
fi

cat > "demo1-rg-selfservice/variables.tf" <<'EOF'
variable "resource_group_name" {
description = "Name of the Azure resource group"
type        = string
default     = ""
}

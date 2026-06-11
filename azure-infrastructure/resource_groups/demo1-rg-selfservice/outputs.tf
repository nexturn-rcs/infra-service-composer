output "resource_group_name" {
  description = "The resource group name"
  value       = var.resource_group_name
}
  EOF
if [ "${DEPLOY_TO}" = "AKS" ] || [ "${DEPLOY_TO}" = "aks" ]; then
  cat > "$TARGET_DIR/aks.tf" <<EOF
provider "azurerm" {
  features = {}
}
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${PROJECT}-${SERVICE}-aks"
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

  cat >> "$TARGET_DIR/outputs.tf" <<'EOF'
  output "aks_cluster_name" {
  description = "AKS cluster name (if created)"
  value       = azurerm_kubernetes_cluster.aks.name
  }
  EOF

cat > "$TARGET_DIR/outputs.tf" <<'EOF'
output "resource_group_name" {
description = "The resource group name"
value       = var.resource_group_name}

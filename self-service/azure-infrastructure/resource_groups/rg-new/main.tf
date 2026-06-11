// Terraform resources for rg-new
// Replace variables as needed.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

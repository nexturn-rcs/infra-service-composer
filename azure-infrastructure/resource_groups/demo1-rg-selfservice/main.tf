//Terraform resources for demo1-rg-selfservice
//Replace variables as needed.    
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
} 
  EOF
cat > "demo1-rg-selfservice/variables.tf" <<'EOF'
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
} 
variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = ""
}
variable "service_name" {
  description = "Service identifier"
  type        = string
  default     = ""
}
variable "tech_stack" {
  description = "Technology stack (e.g. python)"
  type        = string
  default     = ""
}
variable "python_version" {
  description = "Python runtime version"
  type        = string
  default     = ""
}
variable "deploy_to" {
  description = "Deployment target (e.g. AKS)"
  type        = string
  default     = ""
}

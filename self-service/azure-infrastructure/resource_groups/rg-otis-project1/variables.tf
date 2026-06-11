variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-otis-project1"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "otis-project1-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM (required for password authentication). Must meet Azure complexity requirements: 12-123 characters, with 3 of: uppercase, lowercase, numbers, special characters"
  type        = string
  sensitive   = true
  # Users should provide this via environment variable or terraform.tfvars
  # Example: export TF_VAR_admin_password="YourSecurePassword123!"
  # WARNING: Never commit actual passwords to source control
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 50
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    Project     = "OTIS Project 1"
    Ticket      = "INC0010018"
  }
}

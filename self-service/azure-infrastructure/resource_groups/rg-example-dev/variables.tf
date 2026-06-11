variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-example-dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    Project     = "Example"
  }
}

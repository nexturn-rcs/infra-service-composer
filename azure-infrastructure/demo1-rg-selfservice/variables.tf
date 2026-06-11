variable "deploy_to" {
description = "Deployment target (e.g. AKS)"
type        = string
default     = ""
}
variable "location" {
description = "Location of the Azure resource group"
type        = string
default     = "East US"
}
variable "project_name" {
description = "Name of the project"
type        = string
default     = ""
}
variable "service_name" {
description = "Name of the service"
type        = string
default     = ""
}
variable "tech_stack" {
description = "Technology stack used"
type        = string
default     = ""
}

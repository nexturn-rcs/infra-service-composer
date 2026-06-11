terraform {
  required_version = "~> 1.12.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-nextops-otis-tfstate"
    storage_account_name = "nextopsotistfstate"
    container_name       = "tfstate"
    key                  = "rg-otis-project1.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = merge(
    var.common_tags,
    {
      Purpose = "OTIS Project 1 Infrastructure"
      Ticket  = "INC0010018"
    }
  )
}

# Virtual Machine Module
module "ubuntu_vm" {
  source = "git::https://github.com/nex-platform/terraform-modules.git//azure/virtual-machine?ref=develop"
  
  # Resource Configuration
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vm_name            = var.vm_name
  
  # Network Configuration
  vnet_name             = "${var.resource_group_name}-vnet"
  vnet_address_space    = var.vnet_address_space
  subnet_name           = "default"
  subnet_address_prefix = var.subnet_address_prefix
  
  # Network Security Group
  nsg_name = "${var.vm_name}-nsg"
  nsg_rules = [
    {
      name                       = "AllowSSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTP"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPS"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  # Network Interface
  nic_name         = "${var.vm_name}-nic"
  create_public_ip = true
  public_ip_name   = "${var.vm_name}-pip"
  
  # VM Configuration
  vm_size = var.vm_size
  
  # Admin Credentials - Using password authentication for automation
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  
  # OS Image - Ubuntu 22.04 LTS Latest
  os_publisher = "Canonical"
  os_offer     = "0001-com-ubuntu-server-jammy"
  os_sku       = "22_04-lts-gen2"
  os_version   = "latest"
  
  # OS Disk Configuration
  os_disk_caching              = "ReadWrite"
  os_disk_storage_account_type = "Standard_LRS"
  os_disk_size_gb              = var.os_disk_size_gb
  
  # Networking - Fixed parameter name for azurerm v4 compatibility
  accelerated_networking_enabled = false
  
  # Tags
  tags = merge(
    var.common_tags,
    {
      Ticket = "INC0010018"
    }
  )
}

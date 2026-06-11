output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = module.ubuntu_vm.vm_id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.ubuntu_vm.vm_name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = module.ubuntu_vm.vm_private_ip
}

output "vm_public_ip" {
  description = "Public IP address of the VM (for SSH access)"
  value       = module.ubuntu_vm.vm_public_ip
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.ubuntu_vm.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.ubuntu_vm.vnet_name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.ubuntu_vm.subnet_id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.ubuntu_vm.subnet_name
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = module.ubuntu_vm.nsg_id
}

output "nsg_name" {
  description = "Name of the network security group"
  value       = module.ubuntu_vm.nsg_name
}

output "nic_id" {
  description = "ID of the network interface"
  value       = module.ubuntu_vm.nic_id
}

output "nic_name" {
  description = "Name of the network interface"
  value       = module.ubuntu_vm.nic_name
}

output "vm_login_details" {
  description = "VM Login Information"
  value = {
    username   = var.admin_username
    public_ip  = module.ubuntu_vm.vm_public_ip
    ssh_command = "ssh ${var.admin_username}@${module.ubuntu_vm.vm_public_ip}"
  }
}

output "vm_login_instructions" {
  description = "Instructions to login to the VM"
  value       = <<-EOT
    
    ================================
    VM Login Details
    ================================
    VM Name: ${module.ubuntu_vm.vm_name}
    Public IP: ${module.ubuntu_vm.vm_public_ip}
    Private IP: ${module.ubuntu_vm.vm_private_ip}
    Username: ${var.admin_username}
    
    To connect via SSH:
    ssh ${var.admin_username}@${module.ubuntu_vm.vm_public_ip}
    
    Note: Use the password set in the admin_password variable
    ================================
  EOT
}

# OTIS Project 1 Infrastructure

This directory contains Terraform configuration for the OTIS Project 1 Azure infrastructure.

## Ticket Information
- **Ticket ID**: INC0010018
- **Project**: OTIS Project 1
- **Environment**: Production

## Infrastructure Components

### Resource Group
- **Name**: rg-otis-project1
- **Location**: East US

### Networking
- **Virtual Network**: rg-otis-project1-vnet
  - Address Space: 10.0.0.0/16
- **Subnet**: default
  - Address Prefix: 10.0.1.0/24
- **Network Security Group**: otis-project1-vm-nsg
  - Allows SSH (port 22)
  - Allows HTTP (port 80)
  - Allows HTTPS (port 443)

### Virtual Machine
- **VM Name**: otis-project1-vm
- **OS**: Ubuntu 22.04 LTS (Latest)
- **Size**: Standard_B2s
- **Disk**: 20GB Standard LRS
- **Authentication**: SSH Key (Secure)
- **Public IP**: Enabled for remote access

## Terraform Backend Configuration

This configuration uses Azure Storage for remote state:
- **Resource Group**: rg-nextops-otis-tfstate
- **Storage Account**: nextopsotistfstate
- **Container**: tfstate
- **State File**: rg-otis-project1.tfstate

## Prerequisites

1. Azure CLI installed and configured
2. Terraform v1.12.0 installed
3. Appropriate Azure permissions to create resources
4. Access to the Terraform state storage account
5. SSH key pair generated (see below)

## Generating SSH Keys

If you don't have an SSH key pair, generate one:

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# This creates two files:
# ~/.ssh/id_rsa (private key - keep this secure!)
# ~/.ssh/id_rsa.pub (public key - this is what you'll provide to Terraform)

# View your public key
cat ~/.ssh/id_rsa.pub
```

## Usage

### Initialize Terraform
```bash
cd resource_groups/rg-otis-project1
terraform init
```

### Set SSH Public Key

You must provide your SSH public key for VM authentication. You can do this in one of these ways:

1. **Environment Variable** (Recommended):
```bash
export TF_VAR_admin_ssh_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... your_email@example.com"
```

2. **terraform.tfvars file**:
```hcl
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... your_email@example.com"
```

3. **Command line**:
```bash
terraform plan -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

### Plan Infrastructure
```bash
terraform plan
```

### Deploy Infrastructure
```bash
terraform apply
```

### View Outputs
After deployment, Terraform will display the VM login details:
```bash
terraform output vm_login_instructions
```

To get specific outputs:
```bash
terraform output vm_public_ip
terraform output vm_login_details
```

## Accessing the VM

After successful deployment, connect to the VM using SSH with your private key:

```bash
# SSH into the VM using the private key
ssh -i ~/.ssh/id_rsa azureuser@<PUBLIC_IP>

# Or if your key is the default, simply:
ssh azureuser@<PUBLIC_IP>
```

The public IP will be displayed in the Terraform outputs.

## Module Source

This configuration uses the reusable Azure Virtual Machine module from:
- **Repository**: https://github.com/nex-platform/terraform-modules
- **Branch**: develop
- **Module Path**: azure/virtual-machine

## Destroying Infrastructure

To remove all resources:
```bash
terraform destroy
```

## Notes

- ✅ The VM is configured with **SSH key authentication** for enhanced security (recommended best practice)
- 🔒 Password authentication is **disabled** by default
- The admin username is `azureuser` by default but can be customized via variables
- All resources are tagged with the ticket number INC0010018 for tracking purposes
- Network Security Group is configured to allow SSH access from any IP. Consider restricting this in production.

## Security Considerations

✅ **Security Best Practices Implemented**:
1. SSH key authentication enabled (more secure than passwords)
2. Password authentication disabled
3. Sensitive variables marked as sensitive in Terraform

⚠️ **Additional Security Recommendations**:
1. Never commit private keys or sensitive data to version control
2. Use Azure Key Vault for storing secrets in production
3. Restrict NSG rules to known IP addresses when possible
4. Enable Azure Security Center recommendations
5. Regularly update the VM OS and installed packages
6. Consider implementing Just-In-Time (JIT) VM access

## Troubleshooting

### "Permission denied (publickey)" Error
If you get this error when connecting:
1. Ensure you're using the correct private key: `ssh -i ~/.ssh/id_rsa azureuser@<PUBLIC_IP>`
2. Check that your private key has correct permissions: `chmod 600 ~/.ssh/id_rsa`
3. Verify the public key was correctly provided to Terraform

### SSH Key Format
- Ensure your public key is in OpenSSH format (starts with `ssh-rsa` or `ssh-ed25519`)
- The key should be a single line (no line breaks)

## Support

For issues or questions related to this infrastructure:
- Refer to ticket INC0010018
- Contact: DevOps Team
- Module Documentation: [Virtual Machine Module README](https://github.com/nex-platform/terraform-modules/blob/develop/azure/virtual-machine/README.md)

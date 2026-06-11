# Azure Infrastructure Repository

This repository manages Azure infrastructure using Terraform with automated GitHub Actions workflows.

## Repository Structure

```
azure-infrastructure/
├── .github/
│   └── workflows/
│       ├── terraform-state-init.yml      # Initialize Terraform state backend
│       └── terraform-operations.yml      # Run Terraform plan/apply/destroy
├── resource_groups/
│   └── <resource-group-name>/
│       ├── main.tf                       # Main Terraform configuration
│       ├── variables.tf                  # Variable definitions
│       ├── outputs.tf                    # Output definitions
│       └── backend.tf                    # Backend configuration
└── README.md
```

## Prerequisites

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

- `AZURE_CLIENT_ID` - Azure Service Principal Client ID
- `AZURE_CLIENT_SECRET` - Azure Service Principal Client Secret
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `AZURE_TENANT_ID` - Azure Tenant ID

### Service Principal Permissions

The Service Principal needs the following permissions:
- **Contributor** role on the subscription (or specific resource groups)
- **Storage Blob Data Contributor** on the state storage account

## Workflows

### 1. Terraform State Init Workflow

**Purpose:** Initialize the Azure backend for Terraform state management.

**What it creates:**
- Resource Group: `rg-nextops-otis-tfstate`
- Storage Account: `nextopsotistfstate`
- Blob Container: `tfstate`
- Enables blob versioning for state file protection

**Usage:**
1. Go to Actions → Terraform State Init
2. Click "Run workflow"
3. Type `initialize` to confirm
4. Click "Run workflow"

**Note:** This workflow only needs to be run once to set up the state backend.

### 2. Terraform Operations Workflow

**Purpose:** Execute Terraform operations (plan, apply, destroy) on resource groups.

**Inputs:**
- **resource_group**: Name of the resource group (must match directory name under `resource_groups/`)
- **operation**: Choose from `plan`, `apply`, or `destroy`
- **auto_approve**: Enable for automatic approval of apply/destroy operations (default: false)

**Usage:**
1. Go to Actions → Terraform Operations
2. Click "Run workflow"
3. Select branch (e.g., `develop`)
4. Enter resource group name
5. Select operation type
6. Enable auto-approve if needed (⚠️ use with caution)
7. Click "Run workflow"

## Creating New Infrastructure

### Step 1: Create Directory Structure

```bash
mkdir -p resource_groups/<your-resource-group-name>
cd resource_groups/<your-resource-group-name>
```

### Step 2: Create Backend Configuration

Create `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nextops-otis-tfstate"
    storage_account_name = "nextopsotistfstate"
    container_name       = "tfstate"
    key                  = "<your-resource-group-name>.tfstate"
  }
}
```

### Step 3: Create Main Configuration

Create `main.tf`:

```hcl
terraform {
  required_version = "~> 1.12.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Your Azure resources here
resource "azurerm_resource_group" "example" {
  name     = "<your-resource-group-name>"
  location = "East US"
  
  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

### Step 4: Commit and Push

```bash
git add .
git commit -m "INC0010015: Add Terraform configuration for <your-resource-group-name>"
git push origin feature/INC0010015
```

### Step 5: Run Terraform Operations

Use the GitHub Actions workflow to:
1. Run `plan` to preview changes
2. Run `apply` with auto-approve to create resources
3. Run `destroy` with auto-approve to clean up resources

## State File Management

Each resource group has its own state file:
- **Naming convention:** `<resource-group-name>.tfstate`
- **Storage location:** Azure Blob Storage
- **Container:** `tfstate`
- **Versioning:** Enabled for state file history and recovery

## Best Practices

1. **Always run `plan` first** before applying changes
2. **Review the plan output** carefully before approving
3. **Use feature branches** for infrastructure changes
4. **Create Pull Requests** for peer review
5. **Tag resources** appropriately (Environment, ManagedBy, Owner, etc.)
6. **Document complex configurations** with comments
7. **Use variables** for reusable values
8. **Keep state files secure** - never commit them to Git

## Troubleshooting

### Common Issues

**Issue:** "Directory does not exist"
- **Solution:** Ensure the directory structure follows `resource_groups/<resource-group-name>/`

**Issue:** "State file not found"
- **Solution:** Run Terraform State Init workflow first to create the backend

**Issue:** "Authentication failed"
- **Solution:** Verify GitHub secrets are correctly configured

**Issue:** "Permission denied"
- **Solution:** Ensure Service Principal has appropriate RBAC roles

### Getting Help

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review Azure Portal for resource status
3. Contact the DevOps team

## Security Considerations

- ✅ State files stored in encrypted Azure Blob Storage
- ✅ Service Principal authentication via GitHub Secrets
- ✅ HTTPS-only storage account access
- ✅ Blob versioning enabled for state recovery
- ✅ Public blob access disabled
- ✅ TLS 1.2 minimum version enforced

## Contributing

1. Create a feature branch from `develop`
2. Add your Terraform configurations under `resource_groups/`
3. Test using the Terraform Operations workflow
4. Create a Pull Request to `develop`
5. Request review from team members
6. Merge after approval

## License

Internal use only - Nex Platform Organization

---

**Maintained by:** DevOps Team  
**Last Updated:** 2024  
**Terraform Version:** 1.12.1

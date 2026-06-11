# Pipeline Integration Guide for rg-otis-project1

This guide explains how to securely deploy the rg-otis-project1 Azure infrastructure using a CI/CD pipeline with hardcoded credentials in terraform.tfvars.

## 🔒 Security Best Practices

### ⚠️ CRITICAL SECURITY WARNINGS

1. **Never commit terraform.tfvars with actual passwords to version control**
2. **Store sensitive tfvars files in secure secret management systems**
3. **Use pipeline secrets/variables to inject credentials at runtime**
4. **Rotate passwords regularly (every 90 days minimum)**
5. **Use Azure Key Vault in production environments**

---

## 📋 Prerequisites

- Azure subscription with appropriate permissions
- CI/CD pipeline system (Azure DevOps, GitHub Actions, GitLab CI, etc.)
- Secure secret storage capability in your pipeline tool
- Terraform v1.12.1 or later

---

## 🚀 Pipeline Setup Options

### Option 1: Azure DevOps Pipeline (Recommended)

#### Step 1: Store terraform.tfvars as a Secure File

1. Go to **Pipelines** → **Library** → **Secure Files**
2. Upload your `terraform.tfvars` file with the actual password
3. Name it: `rg-otis-project1-terraform.tfvars`

#### Step 2: Create Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - feature/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-vars  # Variable group for non-sensitive configs
  - name: TF_VERSION
    value: '1.12.1'
  - name: WORKING_DIR
    value: 'resource_groups/rg-otis-project1'

stages:
  - stage: Validate
    displayName: 'Terraform Validate'
    jobs:
      - job: Validate
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: $(TF_VERSION)

          - task: DownloadSecureFile@1
            name: tfvars
            displayName: 'Download terraform.tfvars'
            inputs:
              secureFile: 'rg-otis-project1-terraform.tfvars'

          - script: |
              cp $(tfvars.secureFilePath) $(WORKING_DIR)/terraform.tfvars
            displayName: 'Copy terraform.tfvars to working directory'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: $(WORKING_DIR)
              backendServiceArm: 'AzureServiceConnection'
              backendAzureRmResourceGroupName: 'terraform-state-rg'
              backendAzureRmStorageAccountName: 'tfstatestorage'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'rg-otis-project1.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: $(WORKING_DIR)

  - stage: Plan
    displayName: 'Terraform Plan'
    dependsOn: Validate
    condition: succeeded()
    jobs:
      - job: Plan
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: $(TF_VERSION)

          - task: DownloadSecureFile@1
            name: tfvars
            displayName: 'Download terraform.tfvars'
            inputs:
              secureFile: 'rg-otis-project1-terraform.tfvars'

          - script: |
              cp $(tfvars.secureFilePath) $(WORKING_DIR)/terraform.tfvars
            displayName: 'Copy terraform.tfvars'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: $(WORKING_DIR)
              backendServiceArm: 'AzureServiceConnection'
              backendAzureRmResourceGroupName: 'terraform-state-rg'
              backendAzureRmStorageAccountName: 'tfstatestorage'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'rg-otis-project1.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: $(WORKING_DIR)
              environmentServiceNameAzureRM: 'AzureServiceConnection'

  - stage: Apply
    displayName: 'Terraform Apply'
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: Apply
        displayName: 'Deploy Infrastructure'
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: TerraformInstaller@0
                  inputs:
                    terraformVersion: $(TF_VERSION)

                - task: DownloadSecureFile@1
                  name: tfvars
                  displayName: 'Download terraform.tfvars'
                  inputs:
                    secureFile: 'rg-otis-project1-terraform.tfvars'

                - script: |
                    cp $(tfvars.secureFilePath) $(WORKING_DIR)/terraform.tfvars
                  displayName: 'Copy terraform.tfvars'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    workingDirectory: $(WORKING_DIR)
                    backendServiceArm: 'AzureServiceConnection'
                    backendAzureRmResourceGroupName: 'terraform-state-rg'
                    backendAzureRmStorageAccountName: 'tfstatestorage'
                    backendAzureRmContainerName: 'tfstate'
                    backendAzureRmKey: 'rg-otis-project1.tfstate'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: $(WORKING_DIR)
                    environmentServiceNameAzureRM: 'AzureServiceConnection'
```

---

### Option 2: GitHub Actions

#### Step 1: Store terraform.tfvars as a Secret

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `TERRAFORM_TFVARS`
4. Value: Paste the entire contents of your terraform.tfvars file

#### Step 2: Create GitHub Actions Workflow

```yaml
# .github/workflows/terraform.yml
name: Terraform Deploy

on:
  push:
    branches:
      - main
      - feature/*
  pull_request:
    branches:
      - main

env:
  TF_VERSION: '1.12.1'
  WORKING_DIR: 'resource_groups/rg-otis-project1'
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}

jobs:
  validate:
    name: Terraform Validate
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Create terraform.tfvars from secret
        run: |
          echo "${{ secrets.TERRAFORM_TFVARS }}" > ${{ env.WORKING_DIR }}/terraform.tfvars
        shell: bash

      - name: Terraform Init
        run: terraform init
        working-directory: ${{ env.WORKING_DIR }}

      - name: Terraform Validate
        run: terraform validate
        working-directory: ${{ env.WORKING_DIR }}

      - name: Cleanup sensitive files
        if: always()
        run: rm -f ${{ env.WORKING_DIR }}/terraform.tfvars

  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Create terraform.tfvars from secret
        run: |
          echo "${{ secrets.TERRAFORM_TFVARS }}" > ${{ env.WORKING_DIR }}/terraform.tfvars
        shell: bash

      - name: Terraform Init
        run: terraform init
        working-directory: ${{ env.WORKING_DIR }}

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ${{ env.WORKING_DIR }}

      - name: Upload plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: ${{ env.WORKING_DIR }}/tfplan
          retention-days: 5

      - name: Cleanup sensitive files
        if: always()
        run: rm -f ${{ env.WORKING_DIR }}/terraform.tfvars

  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Create terraform.tfvars from secret
        run: |
          echo "${{ secrets.TERRAFORM_TFVARS }}" > ${{ env.WORKING_DIR }}/terraform.tfvars
        shell: bash

      - name: Terraform Init
        run: terraform init
        working-directory: ${{ env.WORKING_DIR }}

      - name: Download plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: ${{ env.WORKING_DIR }}

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        working-directory: ${{ env.WORKING_DIR }}

      - name: Cleanup sensitive files
        if: always()
        run: rm -f ${{ env.WORKING_DIR }}/terraform.tfvars
```

---

### Option 3: GitLab CI/CD

#### Step 1: Store terraform.tfvars as a File Variable

1. Go to **Settings** → **CI/CD** → **Variables**
2. Click **Add variable**
3. Type: **File**
4. Key: `TERRAFORM_TFVARS_FILE`
5. Value: Paste the entire contents of your terraform.tfvars file
6. Check: **Protected** and **Masked**

#### Step 2: Create GitLab CI Pipeline

```yaml
# .gitlab-ci.yml
variables:
  TF_VERSION: "1.12.1"
  WORKING_DIR: "resource_groups/rg-otis-project1"

stages:
  - validate
  - plan
  - apply

before_script:
  - wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
  - unzip terraform_${TF_VERSION}_linux_amd64.zip
  - mv terraform /usr/local/bin/
  - terraform --version

validate:
  stage: validate
  script:
    - cp $TERRAFORM_TFVARS_FILE ${WORKING_DIR}/terraform.tfvars
    - cd ${WORKING_DIR}
    - terraform init
    - terraform validate
  after_script:
    - rm -f ${WORKING_DIR}/terraform.tfvars
  only:
    - branches

plan:
  stage: plan
  script:
    - cp $TERRAFORM_TFVARS_FILE ${WORKING_DIR}/terraform.tfvars
    - cd ${WORKING_DIR}
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${WORKING_DIR}/tfplan
    expire_in: 1 week
  after_script:
    - rm -f ${WORKING_DIR}/terraform.tfvars
  only:
    - branches

apply:
  stage: apply
  script:
    - cp $TERRAFORM_TFVARS_FILE ${WORKING_DIR}/terraform.tfvars
    - cd ${WORKING_DIR}
    - terraform init
    - terraform apply -auto-approve tfplan
  after_script:
    - rm -f ${WORKING_DIR}/terraform.tfvars
  only:
    - main
  when: manual
  environment:
    name: production
```

---

## 🔐 Enhanced Security Options

### Option A: Use Azure Key Vault (Production Recommended)

Instead of hardcoding passwords, reference Azure Key Vault in your terraform.tfvars:

```hcl
# terraform.tfvars
location = "East US"

# Reference to Azure Key Vault secret
# The pipeline will retrieve this at runtime
admin_password = "" # Retrieved from Key Vault by pipeline
```

**Pipeline script to retrieve from Key Vault:**

```bash
# Azure DevOps / GitHub Actions / GitLab CI
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
export TF_VAR_admin_password=$(az keyvault secret show --name vm-admin-password --vault-name your-keyvault --query value -o tsv)
```

### Option B: Use HashiCorp Vault

```bash
export VAULT_ADDR='https://vault.example.com'
export VAULT_TOKEN='your-vault-token'
export TF_VAR_admin_password=$(vault kv get -field=password secret/azure/vm-credentials)
```

---

## 📝 terraform.tfvars Template

Here's what your terraform.tfvars should look like:

```hcl
# Terraform Variables for rg-otis-project1
# ⚠️ DO NOT COMMIT THIS FILE TO VERSION CONTROL

# Azure Location
location = "East US"

# Virtual Machine Admin Password
# ⚠️ REPLACE WITH YOUR ACTUAL SECURE PASSWORD
admin_password = "YourSecureP@ssw0rd123!"

# Optional: Uncomment to customize VM size
# vm_size = "Standard_B2s"
```

---

## ✅ Deployment Checklist

- [ ] terraform.tfvars file created with strong password
- [ ] Password meets Azure requirements (12-123 chars, 3 of 4 character types)
- [ ] terraform.tfvars stored in pipeline secret management system
- [ ] .gitignore updated to exclude *.tfvars files
- [ ] Pipeline YAML/configuration file created
- [ ] Azure service principal credentials configured in pipeline
- [ ] Terraform backend configured for state management
- [ ] Manual approval gate configured for production apply (recommended)
- [ ] Password rotation schedule established
- [ ] Access logs and audit trails enabled

---

## 🛠️ Testing the Pipeline

### Local Testing (Development Only)

```bash
# Navigate to the working directory
cd resource_groups/rg-otis-project1

# Ensure terraform.tfvars exists with your password
cat terraform.tfvars

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Create execution plan
terraform plan

# Apply (only after reviewing the plan)
terraform apply
```

⚠️ **Remember to delete terraform.tfvars after local testing!**

---

## 📊 Monitoring and Auditing

### Enable Azure Activity Logs
```bash
az monitor activity-log list --resource-group rg-otis-project1
```

### Track Terraform State Changes
```bash
terraform show
terraform state list
```

### Review Pipeline Execution History
- Check your pipeline platform's run history
- Review approval gates and deployment logs
- Monitor for failed authentication attempts

---

## 🔄 Password Rotation Process

**Recommended Schedule: Every 90 days**

1. Generate new secure password
2. Update terraform.tfvars in secure storage
3. Update the pipeline secret/variable
4. Run `terraform apply` to update the VM password
5. Document the rotation in your change management system
6. Verify new password works

---

## ❓ Troubleshooting

### Issue: terraform.tfvars not found in pipeline

**Solution:**
```bash
# Verify the file is being created
ls -la resource_groups/rg-otis-project1/
cat resource_groups/rg-otis-project1/terraform.tfvars
```

### Issue: Password authentication fails

**Solution:**
- Verify password meets Azure requirements
- Check NSG rules allow SSH (port 22)
- Ensure `disable_password_authentication = false` in main.tf

### Issue: Terraform state locked

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
```

---

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure VM Password Requirements](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/faq#what-are-the-password-requirements-when-creating-a-vm-)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Key Vault Integration](https://learn.microsoft.com/en-us/azure/key-vault/)

---

## 📞 Support

For issues or questions:
- Open an issue in the repository
- Contact the DevOps team
- Reference incident: **INC0010018**

---

**Last Updated:** 2026-02-23  
**Version:** 1.0  
**Maintained by:** DevOps Team

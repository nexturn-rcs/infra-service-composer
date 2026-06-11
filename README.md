# infra-service-composer for OTIS Demo
Infra Service Composer

## CI: AKS Provisioning (Terraform)

- **Workflow file**: [.github/workflows/azure-aks-terraform.yml](.github/workflows/azure-aks-terraform.yml#L1)
- **How to run**: Actions → select "Provision AKS (Terraform)" → `Run workflow` and fill inputs.
- **Dispatch inputs** (required): `project_name`, `service_name`, `tech_stack`, `python_version`, `deploy_to`.
- Optional: `tf_path` to point to your Terraform templates (default: `terraform`).
 - Optional: `tf_path` to point to your Terraform templates (default: `templates/templates/service-composer/skeleton` in this repo).
- **Required repo secrets**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (used for OIDC federated credential). Do not store long-lived client secrets in repo secrets when using OIDC.
- **Permissions**: the workflow sets `permissions: id-token: write`; ensure repository-level Actions permissions allow workflows to request id tokens if your organization restricts it.

### Federated identity setup (quick)

1. Create a service principal in Azure and assign it the necessary role on the subscription/resource group.
2. In Azure AD → App registrations → select the app (service principal) → `Federated credentials` → add a credential for GitHub Actions (use the repo or organization as issuer and the workflow's repository path as subject).
3. Add the service principal's client id to repository secret `AZURE_CLIENT_ID`, and set `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` as secrets.
4. Trigger the workflow; it uses `azure/login@v3` with OIDC to authenticate.

If you want, I can add a longer README section with screenshots and exact Azure CLI/Portal commands for each step.

## Self-service onboarding workflow (inputs and example)

- **Workflow file**: [self-service/.github/workflows/azure-infrastructure-onboarding.yaml](self-service/.github/workflows/azure-infrastructure-onboarding.yaml#L1)
- **How to run**: Actions → select "Provision AKS (Terraform)" (or the self-service onboarding workflow) → `Run workflow` and fill inputs.

Required dispatch inputs:

- **project_name**: Project name (used to name resources)
- **service_name**: Service name
- **tech_stack**: Tech stack (e.g. python)
- **python_version**: Python version (e.g. 3.11)
- **deploy_to**: Deployment target (use `AKS` to enable AKS)
- **location**: Azure region (e.g. `eastus`)
- **environment**: Deployment environment (e.g. `dev`, `staging`, `prod`)
- **resource_group**: Optional explicit resource group name (workflow derives one if omitted)
- **tf_path**: Optional path to Terraform templates (default: `terraform`)

Example `terraform.tfvars` you can put in your Terraform folder (`tf_path`):

```hcl
project_name  = "myproject"
service_name  = "myservice"
tech_stack    = "python"
python_version = "3.11"
deploy_to     = "AKS"
location      = "eastus"
environment   = "dev"
# resource_group = "myproject-dev-rg" # optional
```

Quick local test (from the Terraform working directory):

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Notes:

- The workflow maps `deploy_to == 'AKS'` to `enable_aks = true` and will attempt to fetch kubeconfig after apply when AKS is enabled.
- Authentication is not configured in the workflow by default; add GitHub Actions OIDC or service-principal login when you are ready.

Pre-checks performed by the workflow

- **Secrets check**: The workflow fails early unless `AZURE_CREDENTIALS` is set or the four service-principal secrets `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`, and `AZURE_TENANT_ID` are present as repository secrets. Set these in the repository Settings → Secrets.
- **TFVars check**: The workflow requires at least one `.tfvars` file (for example `terraform.tfvars`) to exist in the `tf_path` directory. The run will fail if no `.tfvars` files are found.

Add these to the README or repo as needed; I can also add CLI commands to create the service principal and federated credential if you want.

### Azure CLI: create service principal and federated credential for GitHub Actions

Run these commands locally (you must be signed in with an account that can create app registrations and role assignments).

1. Sign in and set subscription:

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

2. Create an app registration and service principal (no client secret needed for OIDC):

```bash
# create app registration
app=$(az ad app create --display-name "github-actions-${GITHUB_ORG}-${GITHUB_REPO}" --query "{appId:appId, objectId:objectId}" -o json)
appId=$(echo "$app" | jq -r .appId)
objectId=$(echo "$app" | jq -r .objectId)

# create service principal for the app
az ad sp create --id "$appId"
```

3. Assign a role to the service principal (scope can be subscription or specific resource group):

```bash
az role assignment create --assignee $appId --role "Contributor" --scope /subscriptions/<SUBSCRIPTION_ID>
```

4. Create the federated credential that allows GitHub Actions to request tokens (replace `ORG/REPO` and `refs/heads/main` as appropriate):

```bash
cat > federated-cred.json <<EOF
{
	"name": "github-actions-federated-cred",
	"issuer": "https://token.actions.githubusercontent.com",
	"subject": "repo:<GITHUB_ORG>/<GITHUB_REPO>:ref:refs/heads/main",
	"description": "Federated credential for GitHub Actions",
	"audiences": ["api://AzureADTokenExchange"]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/v1.0/applications/$objectId/federatedIdentityCredentials" --body @federated-cred.json --headers "Content-Type=application/json"
```

5. Add repository secrets in GitHub (Settings → Secrets):

- `AZURE_CLIENT_ID` = the `appId` value
- `AZURE_TENANT_ID` = your Azure tenant id (az account show)
- `AZURE_SUBSCRIPTION_ID` = your subscription id

Notes and troubleshooting:

- The `az rest` call requires your signed-in user to have permissions to update the application (Owner or Application Administrator). If you get permission errors, perform the federated credential creation in the Azure Portal (App registrations → your app → Federated credentials).
- If you prefer to use an App client secret instead of OIDC, create it with `az ad app credential reset --id $appId` and store the returned client secret in the `AZURE_CLIENT_SECRET` secret (workflow currently does not use it until you re-enable non-OIDC auth).


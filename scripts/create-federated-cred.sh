#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --subscription SUBSCRIPTION_ID --org GITHUB_ORG --repo GITHUB_REPO [options]

Options:
  --subscription SUBSCRIPTION_ID   Azure subscription id (required)
  --org GITHUB_ORG                 GitHub organization or user (required)
  --repo GITHUB_REPO               GitHub repository name (required)
  --branch BRANCH                  Git ref branch to trust (default: main)
  --name DISPLAY_NAME              App display name (default: github-actions-<org>-<repo>)
  --scope SCOPE                    Role assignment scope (default: /subscriptions/<SUBSCRIPTION_ID>)
  --role ROLE                      Role to assign (default: Contributor)
  -h, --help                       Show this help

Example:
  $0 --subscription 0000-0000-0000 --org my-org --repo my-repo --branch main

Note: you must be logged in with `az login` and have permissions to create app registrations and role assignments.
EOF
}

# defaults
BRANCH=main
DISPLAY_NAME=""
ROLE="Contributor"

# parse args
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription)
      SUBSCRIPTION_ID="$2"; shift 2;;
    --org)
      GITHUB_ORG="$2"; shift 2;;
    --repo)
      GITHUB_REPO="$2"; shift 2;;
    --branch)
      BRANCH="$2"; shift 2;;
    --name)
      DISPLAY_NAME="$2"; shift 2;;
    --scope)
      SCOPE="$2"; shift 2;;
    --role)
      ROLE="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

# required
: "${SUBSCRIPTION_ID:?--subscription is required}"
: "${GITHUB_ORG:?--org is required}"
: "${GITHUB_REPO:?--repo is required}"

if [ -z "$DISPLAY_NAME" ]; then
  DISPLAY_NAME="github-actions-${GITHUB_ORG}-${GITHUB_REPO}"
fi

if [ -z "${SCOPE:-}" ]; then
  SCOPE="/subscriptions/${SUBSCRIPTION_ID}"
fi

# checks
command -v az >/dev/null 2>&1 || { echo "az CLI not found. Install Azure CLI and retry."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found. Install jq for JSON parsing and retry."; exit 1; }

echo "Using subscription: $SUBSCRIPTION_ID"
az account show --subscription "$SUBSCRIPTION_ID" >/dev/null

echo "Creating app registration '$DISPLAY_NAME'..."
app_json=$(az ad app create --display-name "$DISPLAY_NAME" --query '{appId:appId, objectId:objectId}' -o json)
appId=$(echo "$app_json" | jq -r .appId)
objectId=$(echo "$app_json" | jq -r .objectId)

if [ -z "$appId" ] || [ -z "$objectId" ]; then
  echo "Failed to create app registration. Exiting."
  echo "$app_json"
  exit 1
fi

echo "App created. appId=$appId objectId=$objectId"

# create service principal (no secret) - ignore error if it already exists
echo "Creating service principal for appId..."
set +e
az ad sp create --id "$appId" >/dev/null 2>&1
sp_rc=$?
set -e
if [ $sp_rc -ne 0 ]; then
  echo "Service principal may already exist, continuing..."
fi

# assign role
echo "Assigning role '$ROLE' to $appId at scope $SCOPE"
az role assignment create --assignee "$appId" --role "$ROLE" --scope "$SCOPE"

# create federated credential JSON
CRED_NAME="github-actions-${GITHUB_ORG}-${GITHUB_REPO}-cred"
SUBJECT="repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/${BRANCH}"

cat > /tmp/federated-cred.json <<EOF
{
  "name": "${CRED_NAME}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${SUBJECT}",
  "description": "Federated credential for GitHub Actions",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

echo "Adding federated credential to the application (requires Graph API permissions for your user)..."
set +e
az rest --method POST --uri "https://graph.microsoft.com/v1.0/applications/${objectId}/federatedIdentityCredentials" --body @/tmp/federated-cred.json --headers "Content-Type=application/json"
rc=$?
set -e

if [ $rc -ne 0 ]; then
  echo "Failed to create federated credential via az rest. You may not have sufficient permissions."
  echo "You can create the federated credential in the Azure Portal: App registrations -> Select app -> Federated credentials -> Add GitHub Actions entry (issuer: token.actions.githubusercontent.com, subject: ${SUBJECT})"
  exit 1
fi

# output values
tenantId=$(az account show --query tenantId -o tsv)

echo "Success. Set these repository secrets in GitHub (Repository Settings -> Secrets):"
echo "  AZURE_CLIENT_ID=${appId}"
echo "  AZURE_TENANT_ID=${tenantId}"
echo "  AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}"

echo "Optional: if you need to use client secret auth instead of OIDC, create a client secret with:"
echo "  az ad app credential reset --id ${appId} --append"

echo "Done."

# cleanup
rm -f /tmp/federated-cred.json

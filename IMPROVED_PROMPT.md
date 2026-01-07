# Improved Prompt: Full-Stack Azure Deployment

> **Version 2.0** - Based on real-world deployment learnings and battle-tested solutions

## Critical Prerequisites

**Before starting, ensure you have these MCP servers installed:**

1. **Exa AI MCP Server** - Essential for researching Azure-specific issues and finding community solutions
2. **Microsoft Learn MCP Server** - Required for accessing official Azure documentation

**Without these tools, you'll waste hours in circular debugging loops.** They are not optional.

---

## Project Overview

You are helping me build a production-ready full-stack application using:
- React frontend
- Azure Functions backend (Node.js 20, Azure Functions v4)
- Azure Static Web App hosting (Standard SKU required)
- GitHub Actions for CI/CD with OIDC authentication
- Terraform for infrastructure as code
- **Zero shared keys - managed identities and RBAC only**

---

## Deployment Requirements

### 1. Complete Terraform Configuration (`/infra` folder)

**Critical Requirements:**
- **No shared access keys anywhere** - Use `shared_access_key_enabled = false`
- **Managed identities for all authentication** - System-assigned identities
- **RBAC roles explicitly assigned** - Don't assume Contributor includes data access
- **Azure AD authentication for Terraform state** - Use `use_azuread_auth = true`

**Provision:**

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# Storage Account - RBAC ONLY
resource "azurerm_storage_account" "main" {
  name                     = "st${var.project_name}${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # CRITICAL: No shared keys
  shared_access_key_enabled = false
}

# Function App with Managed Identity
resource "azurerm_linux_function_app" "main" {
  name                = "func-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  storage_account_name       = azurerm_storage_account.main.name
  service_plan_id            = azurerm_service_plan.main.id
  
  # CRITICAL: Use managed identity for storage
  storage_uses_managed_identity = true
  
  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    application_stack {
      node_version = "20"
    }
  }
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "AzureWebJobsFeatureFlags"  = "EnableWorkerIndexing"
  }
  
  # CRITICAL: Ignore Azure-managed settings
  lifecycle {
    ignore_changes = [
      auth_settings_v2
    ]
  }
}

# Static Web App - STANDARD SKU REQUIRED
resource "azurerm_static_web_app" "main" {
  name                = "swa-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  # CRITICAL: Standard SKU required for backend linking
  sku_tier = "Standard"
  sku_size = "Standard"
}

# Link Function App to Static Web App
resource "azurerm_static_web_app_function_app_registration" "main" {
  static_web_app_id = azurerm_static_web_app.main.id
  function_app_id   = azurerm_linux_function_app.main.id
}

# CRITICAL: Explicit RBAC assignments
resource "azurerm_role_assignment" "function_storage_blob" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_storage_queue" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}
```

**Backend Configuration (`backend.hcl`):**

```hcl
storage_account_name = "sttfstate<random>"
container_name       = "tfstate"
key                  = "terraform.tfstate"
resource_group_name  = "rg-terraform-state"

# CRITICAL: Required for RBAC-only storage
use_azuread_auth = true
```

**Variables:**

```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "westus2"  # Use region with quota availability
}

variable "project_name" {
  description = "Project name (lowercase, no spaces)"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "entra_app_client_id" {
  description = "Entra ID app client ID for OIDC"
  type        = string
}

variable "entra_app_tenant_id" {
  description = "Entra ID tenant ID"
  type        = string
}
```

---

### 2. Azure Function App Configuration

**CRITICAL: `api/package.json` must include `main` field for Azure Functions v4:**

```json
{
  "name": "full-stack-demo-api",
  "version": "1.0.0",
  "main": "src/functions/*.js",
  "scripts": {
    "start": "func start"
  },
  "dependencies": {
    "@azure/functions": "^4.0.0"
  }
}
```

**Without the `main` field, Functions v4 will not discover your functions and you'll get "No job functions found" errors.**

---

### 3. Static Web App Configuration

**CRITICAL: Create `frontend/public/staticwebapp.config.json`:**

```json
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    }
  ]
}
```

**This enables API proxying through the Static Web App, avoiding CORS issues.**

**Frontend API calls should use relative paths:**

```javascript
// In your React app
const apiUrl = process.env.REACT_APP_FUNCTION_APP_URL 
  ? `${process.env.REACT_APP_FUNCTION_APP_URL}/api/hello`
  : '/api/hello';  // Relative path - proxied by Static Web App

fetch(apiUrl)
  .then(response => response.json())
  .then(data => console.log(data));
```

**Do NOT hardcode Function App URLs - use relative paths for production.**

---

### 4. GitHub Actions Workflow (`azure-deploy.yml`)

**Critical Requirements:**
- **Use GitHub Environments** - Required for OIDC authentication
- **All jobs must declare environment** - Not just the first job
- **Wait for runs to complete** - Check logs before assuming success
- **Validate against Azure** - Use Azure CLI to check actual state

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    # CRITICAL: Environment required for OIDC
    environment: production
    
    outputs:
      function_app_name: ${{ steps.terraform-output.outputs.function_app_name }}
      function_app_url: ${{ steps.terraform-output.outputs.function_app_url }}
      static_web_app_name: ${{ steps.terraform-output.outputs.static_web_app_name }}
      static_web_app_url: ${{ steps.terraform-output.outputs.static_web_app_url }}
      static_web_app_api_key: ${{ steps.terraform-output.outputs.static_web_app_api_key }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0
      
      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Terraform Init
        run: terraform init -backend-config=backend.hcl
        working-directory: ./infra
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_USE_OIDC: true
      
      - name: Terraform Apply
        run: |
          terraform plan \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -var="entra_app_client_id=${{ secrets.AZURE_CLIENT_ID }}" \
            -var="entra_app_tenant_id=${{ secrets.AZURE_TENANT_ID }}" \
            -out=tfplan
          terraform apply -auto-approve tfplan
        working-directory: ./infra
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_USE_OIDC: true
      
      - name: Get Terraform Outputs
        id: terraform-output
        run: |
          echo "function_app_name=$(terraform output -raw function_app_name)" >> $GITHUB_OUTPUT
          echo "function_app_url=$(terraform output -raw function_app_url)" >> $GITHUB_OUTPUT
          echo "static_web_app_name=$(terraform output -raw static_web_app_name)" >> $GITHUB_OUTPUT
          echo "static_web_app_url=$(terraform output -raw static_web_app_url)" >> $GITHUB_OUTPUT
          echo "static_web_app_api_key=$(terraform output -raw static_web_app_api_key)" >> $GITHUB_OUTPUT
        working-directory: ./infra

  deploy-function:
    name: 'Deploy Function App'
    runs-on: ubuntu-latest
    needs: terraform
    # CRITICAL: Must match terraform job environment
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Install Dependencies
        run: |
          if [ -f package-lock.json ]; then
            npm ci
          else
            npm install
          fi
        working-directory: ./api
      
      - name: Deploy to Azure Functions
        uses: Azure/functions-action@v1
        with:
          app-name: ${{ needs.terraform.outputs.function_app_name }}
          package: ./api

  deploy-frontend:
    name: 'Deploy Static Web App'
    runs-on: ubuntu-latest
    needs: terraform
    # CRITICAL: Must match terraform job environment
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Build React App
        run: |
          if [ -f package-lock.json ]; then
            npm ci
          else
            npm install
          fi
          npm run build
          # DO NOT set REACT_APP_FUNCTION_APP_URL - use relative paths
        working-directory: ./frontend
      
      - name: Deploy Static Web App
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ needs.terraform.outputs.static_web_app_api_key }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: 'upload'
          app_location: './frontend/build'
          output_location: ''
          skip_app_build: true
          # CRITICAL: Deploy to production, not staging
          production_branch: 'main'
      
      - name: Deployment Summary
        run: |
          echo "### Deployment Complete ✅" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Function App:** ${{ needs.terraform.outputs.function_app_url }}" >> $GITHUB_STEP_SUMMARY
          echo "**Static Web App:** ${{ needs.terraform.outputs.static_web_app_url }}" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Test API:** \`curl ${{ needs.terraform.outputs.static_web_app_url }}/api/hello\`" >> $GITHUB_STEP_SUMMARY
```

---

### 5. Setup Documentation

Create a comprehensive setup guide that includes:

**Automated Setup Script:**

```bash
#!/bin/bash

# Azure Setup
SUBSCRIPTION_ID="your-subscription-id"
APP_NAME="GitHub-Actions-OIDC-FullStackDemo"
REPO="owner/repo-name"

# Create Entra ID App Registration
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

# Create Service Principal
SP_OBJECT_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# Assign Roles
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

az role assignment create \
  --assignee $APP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Create Federated Credentials (ALL THREE REQUIRED)
# 1. Main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"main-branch\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# 2. Production environment (CRITICAL)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"production-environment\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:production\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# 3. Pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"pull-requests\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:pull_request\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# Create Terraform State Storage
RANDOM_SUFFIX=$(openssl rand -hex 3)
STORAGE_NAME="sttfstate$RANDOM_SUFFIX"

az group create --name rg-terraform-state --location westus2

az storage account create \
  --name $STORAGE_NAME \
  --resource-group rg-terraform-state \
  --location westus2 \
  --sku Standard_LRS \
  --allow-shared-key-access false

az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME \
  --auth-mode login

# Grant Storage Access to Service Principal
az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME"

# Configure GitHub Secrets
TENANT_ID=$(az account show --query tenantId -o tsv)

gh secret set AZURE_CLIENT_ID --body "$APP_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"

echo "✅ Setup complete!"
echo "Update infra/backend.hcl with storage_account_name: $STORAGE_NAME"
```

---

## Iterative Debugging Strategy

**When deployment fails (and it will), follow this process:**

1. **Wait for completion** - Let the GitHub Actions run finish completely
2. **Check logs** - Use `gh run view <run-id> --log` to see actual errors
3. **Validate Azure state** - Use Azure CLI to check actual resource configuration
   ```bash
   az functionapp show --name <name> --resource-group <rg>
   az staticwebapp show --name <name> --resource-group <rg>
   ```
4. **Research the error** - Use Exa AI to search for the specific error message
5. **Check official docs** - Use MS Learn MCP to find authoritative answers
6. **Make targeted fix** - Change only what's needed based on research
7. **Deploy again** - Commit, push, wait for completion, repeat

**❌ DO NOT:**
- Assume why something failed without checking logs
- Make multiple changes at once
- Skip validation against actual Azure state
- Rely on trial-and-error

**✅ DO:**
- Check logs for every failure
- Research specific error messages
- Validate assumptions against Azure
- Make one change at a time

---

## Known Pitfalls & Solutions

### Pitfall #1: Preview Environments Don't Support Backends
**Problem:** PR deployments create staging URLs but can't link to Function App backend
**Solution:** Test frontend-only in PRs, merge to main for full-stack testing

### Pitfall #2: Azure Functions v4 Won't Discover Functions
**Problem:** "No job functions found" even though functions exist
**Solution:** Add `"main": "src/functions/*.js"` to package.json

### Pitfall #3: CORS Errors with Static Web Apps
**Problem:** Direct Function App calls blocked by CORS
**Solution:** Use relative `/api/*` paths + staticwebapp.config.json

### Pitfall #4: Terraform State Access Denied
**Problem:** 403 errors accessing state storage
**Solution:** Set `use_azuread_auth = true` in backend config

### Pitfall #5: OIDC Authentication Fails
**Problem:** "Failed to login" even with correct secrets
**Solution:** Create federated credential for `environment:production`, add `environment: production` to ALL jobs

### Pitfall #6: Static Web App Serves Old Files
**Problem:** Deployment succeeds but site shows old version
**Solution:** Add `production_branch: 'main'` to Static Web Apps deploy action

---

## Testing Strategy

**Local Development:**
```bash
# Terminal 1 - Backend
cd api
npm install
func start

# Terminal 2 - Frontend
cd frontend
npm install
REACT_APP_FUNCTION_APP_URL=http://localhost:7071 npm start
```

**Azure Testing:**
- Push to main branch for full-stack testing
- PR environments are frontend-only (Azure limitation)
- Consider separate dev Static Web App for staging (~$9/month extra)

---

## Success Criteria

Your deployment is successful when:

✅ Terraform applies without errors
✅ Function App deploys and responds to requests
✅ Static Web App deploys with latest build
✅ API calls work: `curl https://<swa-url>/api/hello`
✅ No CORS errors in browser console
✅ All authentication uses managed identities (zero shared keys)

---

## Cost Estimate

- **Static Web App Standard:** ~$9/month
- **Function App Consumption:** ~$1-5/month (usage-based)
- **Storage Account:** <$1/month
- **Total:** ~$10-15/month for production workload

---

## Additional Resources

- **Use Exa AI** to search for: "Azure Functions v4 Node.js best practices"
- **Use MS Learn** to read: "Azure Static Web Apps documentation"
- **Check deployment logs** with: `gh run view --log`
- **Validate resources** with: `az resource list --resource-group <rg>`

---

**Remember:** The tools (Exa AI, MS Learn MCP) and methodology (wait → check logs → research → fix) are just as important as the code itself. Without them, you'll waste hours debugging. With them, you'll iterate quickly toward a working solution.

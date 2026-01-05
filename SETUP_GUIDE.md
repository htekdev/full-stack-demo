# Quick Setup Guide

This guide will help you get the full-stack demo application deployed to Azure in under 30 minutes.

## Prerequisites Checklist

Before you begin, make sure you have:

- [ ] Azure account with an active subscription
- [ ] GitHub repository (this repo) with admin access
- [ ] Azure CLI installed (`az --version` to check)

## Step-by-Step Setup

### 1. Azure Setup (10 minutes)

#### 1.1 Login to Azure

```bash
az login
```

#### 1.2 Get Your IDs

```bash
# Save these values - you'll need them later
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
```

#### 1.3 Create Entra ID App Registration

```bash
# Create app registration
APP_ID=$(az ad app create \
  --display-name "GitHub-Actions-OIDC-FullStackDemo" \
  --query appId -o tsv)

echo "Client ID (APP_ID): $APP_ID"

# Create service principal
az ad sp create --id $APP_ID

# Assign Contributor role
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

#### 1.4 Configure Federated Credentials

**IMPORTANT**: Replace `YOUR_GITHUB_ORG/YOUR_REPO_NAME` with your actual values!

```bash
# Replace these with your GitHub info
GITHUB_ORG="htekdev"
GITHUB_REPO="full-stack-demo"

# Create federated credential
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-federated-credential\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

#### 1.5 Create Terraform State Storage

```bash
# Choose a unique name for your storage account
STORAGE_SUFFIX=$(echo $RANDOM | md5sum | head -c 5)
STORAGE_NAME="sttfstate${STORAGE_SUFFIX}"

# Create resource group
az group create \
  --name rg-terraform-state \
  --location eastus

# Create storage account
az storage account create \
  --name $STORAGE_NAME \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --account-name $STORAGE_NAME \
  --resource-group rg-terraform-state \
  --query '[0].value' -o tsv)

# Create container
az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY

echo "Storage Account Name: $STORAGE_NAME"
```

### 2. GitHub Secrets Setup (5 minutes)

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

| Secret Name | Value | Where to find it |
|-------------|-------|------------------|
| `AZURE_CLIENT_ID` | `$APP_ID` | Output from step 1.3 |
| `AZURE_TENANT_ID` | `$TENANT_ID` | Output from step 1.2 |
| `AZURE_SUBSCRIPTION_ID` | `$SUBSCRIPTION_ID` | Output from step 1.2 |
| `TERRAFORM_STATE_RG` | `rg-terraform-state` | Created in step 1.5 |
| `TERRAFORM_STATE_STORAGE` | `$STORAGE_NAME` | Output from step 1.5 |
| `TERRAFORM_STATE_CONTAINER` | `tfstate` | Created in step 1.5 |

**Quick Copy Script:**

```bash
echo ""
echo "=== Copy these values to GitHub Secrets ==="
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "TERRAFORM_STATE_RG: rg-terraform-state"
echo "TERRAFORM_STATE_STORAGE: $STORAGE_NAME"
echo "TERRAFORM_STATE_CONTAINER: tfstate"
echo "==========================================="
```

### 3. Deploy! (10-15 minutes)

Once secrets are configured, deployment is automatic:

1. **Push to main branch** (if you haven't already):
   ```bash
   git push origin main
   ```

2. **Watch the deployment**:
   - Go to **Actions** tab in GitHub
   - Click on the running workflow
   - Monitor the progress

3. **Get your URLs**:
   - URLs will appear in the workflow **Summary** page
   - Should complete in 10-15 minutes

### 4. Verify Deployment

After the workflow completes:

#### Check Resources in Azure Portal

1. Go to https://portal.azure.com
2. Search for resource group: `rg-fullstackdemo-dev`
3. You should see:
   - Static Web App
   - Function App
   - Storage Account
   - Service Plan
   - Application Insights

#### Test the Application

```bash
# Get the Static Web App URL
STATIC_APP_URL=$(az staticwebapp show \
  --name swa-fullstackdemo-dev \
  --resource-group rg-fullstackdemo-dev \
  --query "defaultHostname" -o tsv)

echo "Frontend URL: https://$STATIC_APP_URL"

# Get the Function App URL
FUNCTION_URL=$(az functionapp show \
  --name func-fullstackdemo-dev \
  --resource-group rg-fullstackdemo-dev \
  --query "defaultHostName" -o tsv)

echo "API URL: https://$FUNCTION_URL/api/hello"

# Test the API
curl "https://$FUNCTION_URL/api/hello?name=Developer"
```

## Troubleshooting Common Issues

### Issue: "No matching federated identity record found"

**Solution**: The subject in the federated credential must exactly match your repo.

```bash
# Verify your federated credential
az ad app federated-credential list --id $APP_ID

# If wrong, delete and recreate
az ad app federated-credential delete \
  --id $APP_ID \
  --federated-credential-id <credential-id>

# Then recreate with correct subject
```

### Issue: Workflow fails at Terraform Init

**Solution**: Verify Terraform state storage secrets are correct.

```bash
# Check if container exists
az storage container exists \
  --name tfstate \
  --account-name $STORAGE_NAME \
  --account-key $STORAGE_KEY
```

### Issue: Function App deployment fails

**Solution**: Ensure Node.js dependencies are specified correctly in `api/package.json`.

### Issue: Static Web App doesn't load

**Solution**: Check the build output location matches `build` in the workflow.

## What Gets Deployed?

After successful deployment, you'll have:

- ✅ **Frontend**: React app on Azure Static Web Apps
- ✅ **Backend**: Two Azure Functions (`/api/hello` and `/api/healthcheck`)
- ✅ **Infrastructure**: All Azure resources managed by Terraform
- ✅ **Monitoring**: Application Insights collecting telemetry
- ✅ **CI/CD**: Automated deployments on push to main

## Next Steps

1. **Customize the application**:
   - Edit `frontend/src/App.js` for UI changes
   - Add new functions in `api/src/functions/`
   - Modify infrastructure in `infra/main.tf`

2. **Add environments**:
   - Create staging/prod branches
   - Add environment-specific federated credentials
   - Update workflow to deploy to multiple environments

3. **Enable custom domain**:
   - Configure custom domain in Azure Portal
   - Update DNS records
   - Enable SSL certificate

4. **Add authentication**:
   - Configure Azure AD authentication
   - Protect Function App endpoints
   - Add user authentication to React app

## Cost Management

To avoid unexpected charges:

- Static Web App Free tier: $0/month
- Function App (Consumption): ~$0-20/month
- Storage: ~$1-5/month
- Application Insights: ~$0-10/month

**Total estimated cost**: $1-35/month for development

## Cleanup

To delete all resources:

```bash
# Delete main resource group
az group delete \
  --name rg-fullstackdemo-dev \
  --yes --no-wait

# Delete Terraform state resource group
az group delete \
  --name rg-terraform-state \
  --yes --no-wait

# Delete App Registration
az ad app delete --id $APP_ID
```

## Support

- 📖 Full documentation: See [README.md](README.md)
- 🐛 Issues: [GitHub Issues](https://github.com/htekdev/full-stack-demo/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/htekdev/full-stack-demo/discussions)

---

**Ready to deploy?** Start with Step 1! 🚀

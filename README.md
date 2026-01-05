# Full Stack Demo Application

A complete full-stack demo application showcasing modern Azure deployment practices with Infrastructure as Code (IaC) using Terraform and CI/CD using GitHub Actions.

## Architecture

This application demonstrates:
- **Frontend**: React application hosted on Azure Static Web Apps
- **Backend**: Azure Functions (Node.js runtime)
- **Infrastructure**: Terraform for provisioning all Azure resources
- **CI/CD**: GitHub Actions with OIDC authentication
- **Monitoring**: Application Insights for telemetry

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── azure-deploy.yml      # GitHub Actions CI/CD workflow
├── infra/                         # Terraform infrastructure code
│   ├── main.tf                    # Main infrastructure resources
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── providers.tf               # Provider configuration
│   └── terraform.tfvars.example   # Example variables file
├── frontend/                      # React application
└── api/                          # Azure Functions
```

## Prerequisites

Before you begin, ensure you have:

1. **Azure Subscription**: An active Azure subscription
2. **GitHub Account**: Repository access with admin permissions
3. **Azure CLI**: Installed locally for setup (optional)
4. **Terraform**: Version 1.7.0 or higher (for local testing)

## Setup Instructions

### Step 1: Create Entra ID App Registration for OIDC

OIDC (OpenID Connect) allows GitHub Actions to authenticate with Azure without storing long-lived credentials.

#### 1.1 Create the App Registration

```bash
# Login to Azure
az login

# Create the App Registration
az ad app create --display-name "GitHub-Actions-OIDC-FullStackDemo"

# Note the appId from the output - this is your AZURE_CLIENT_ID
```

#### 1.2 Create a Service Principal

```bash
# Create service principal (replace <APP_ID> with your appId)
az ad sp create --id <APP_ID>

# Get your subscription ID and tenant ID
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```

#### 1.3 Assign Azure Permissions

```bash
# Assign Contributor role to the service principal
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

#### 1.4 Configure Federated Identity Credentials

This establishes trust between GitHub and Azure:

```bash
# Create federated credential for main branch
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-federated-credential",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_ORG/YOUR_REPO_NAME:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Important**: Replace `YOUR_GITHUB_ORG/YOUR_REPO_NAME` with your actual GitHub organization and repository name (e.g., `htekdev/full-stack-demo`).

#### 1.5 Create Terraform State Storage

Terraform needs a place to store its state file:

```bash
# Create resource group for Terraform state
az group create \
  --name rg-terraform-state \
  --location eastus

# Create storage account (name must be globally unique)
az storage account create \
  --name sttfstateXXXXX \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name sttfstateXXXXX \
  --auth-mode login
```

Replace `XXXXX` with a unique suffix (e.g., your initials + random numbers).

### Step 2: Configure GitHub Repository Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AZURE_CLIENT_ID` | Application (client) ID from App Registration | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_TENANT_ID` | Directory (tenant) ID from Azure AD | `87654321-4321-4321-4321-abcdefghijkl` |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | `abcdef12-3456-7890-abcd-ef1234567890` |
| `TERRAFORM_STATE_RG` | Resource group for Terraform state | `rg-terraform-state` |
| `TERRAFORM_STATE_STORAGE` | Storage account name for Terraform state | `sttfstateXXXXX` |
| `TERRAFORM_STATE_CONTAINER` | Container name for Terraform state | `tfstate` |

### Step 3: Configure Terraform Variables (Optional)

If you want to customize the deployment, create a `terraform.tfvars` file in the `infra/` directory:

```hcl
subscription_id       = "your-subscription-id"
location              = "eastus"
environment           = "dev"
project_name          = "fullstackdemo"
entra_app_client_id   = "your-client-id"
entra_app_tenant_id   = "your-tenant-id"
```

**Note**: The GitHub Actions workflow passes these values automatically from secrets, so this step is only needed for local testing.

## Deployment Workflow

The deployment happens automatically when you push to the `main` branch:

### Workflow Steps

1. **Terraform Deploy**
   - Authenticates to Azure using OIDC
   - Initializes Terraform with remote backend
   - Validates and formats Terraform code
   - Creates/updates infrastructure:
     - Resource Group
     - Storage Account for Functions
     - App Service Plan (Consumption)
     - Azure Function App
     - Static Web App
     - Application Insights
     - Links Function App to Static Web App
   - Outputs resource information for subsequent jobs

2. **Deploy Azure Function**
   - Builds the Azure Functions code
   - Deploys to the provisioned Function App
   - Verifies deployment

3. **Deploy Static Web App**
   - Builds the React application
   - Deploys to Azure Static Web Apps
   - Automatically handles CDN distribution

4. **Deployment Summary**
   - Creates a comprehensive summary with:
     - Resource URLs
     - Deployment status
     - Quick links for validation

### Monitoring Deployment

After pushing to `main`:

1. Go to **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. View the **Summary** page for deployment URLs
4. Check each job for detailed logs

## Verifying the Deployment

After successful deployment:

### 1. Check Infrastructure

```bash
# Login to Azure
az login

# List resources in the resource group
az resource list \
  --resource-group rg-fullstackdemo-dev \
  --output table
```

### 2. Test Azure Function

```bash
# Get the Function App URL from workflow output or:
FUNCTION_URL=$(az functionapp show \
  --name func-fullstackdemo-dev \
  --resource-group rg-fullstackdemo-dev \
  --query "defaultHostName" -o tsv)

echo "https://${FUNCTION_URL}"
```

### 3. Access Static Web App

The Static Web App URL is shown in the workflow summary. It will be something like:
`https://swa-fullstackdemo-dev-xxxxx.azurestaticapps.net`

## Local Development

### Running Terraform Locally

```bash
cd infra

# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=sttfstateXXXXX" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=full-stack-demo.terraform.tfstate"

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Running React Locally

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

### Running Azure Functions Locally

```bash
cd api

# Install dependencies
npm install

# Start Functions runtime
npm start
```

## Troubleshooting

### OIDC Authentication Fails

**Error**: `AADSTS70021: No matching federated identity record found`

**Solution**: 
- Verify the federated credential subject exactly matches your repo
- Check the format: `repo:OWNER/REPO:ref:refs/heads/main`
- Ensure the credential is created for the correct App Registration

### Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Function App Deployment Fails

**Error**: `Failed to deploy Function App`

**Solution**:
- Ensure `package.json` exists in the `api/` directory
- Check that Node.js version matches in both local and Azure (20)
- Verify the Function App is running: `az functionapp show --name <name> --resource-group <rg>`

### Static Web App Build Fails

**Error**: `Build failed`

**Solution**:
- Verify `package.json` exists in `frontend/` directory
- Check build command: `npm run build`
- Ensure output directory is `build` for React

## Architecture Decisions

### Why OIDC over Service Principal Secrets?

- **Security**: No long-lived credentials stored in GitHub
- **Rotation**: No need to rotate secrets manually
- **Audit**: Better audit trail with federated identity
- **Least Privilege**: Scoped per repository/branch

### Why Consumption Plan for Functions?

- **Cost**: Pay only for execution time
- **Scale**: Automatic scaling
- **Demo**: Perfect for demo applications with variable load

### Why Terraform?

- **Declarative**: Infrastructure as Code
- **Version Control**: Track changes over time
- **Reproducible**: Consistent deployments across environments
- **State Management**: Understand current vs desired state

## Resources Created

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| Resource Group | `rg-{project}-{env}` | Container for all resources |
| Storage Account | `st{project}{env}` | Backend storage for Functions |
| App Service Plan | `asp-{project}-{env}` | Hosting plan for Functions |
| Function App | `func-{project}-{env}` | Serverless functions backend |
| Static Web App | `swa-{project}-{env}` | Frontend hosting |
| Application Insights | `appi-{project}-{env}` | Monitoring and telemetry |

## Security Best Practices

1. **OIDC Authentication**: No secrets stored in GitHub
2. **HTTPS Only**: All apps configured with HTTPS
3. **Managed Identity**: Where applicable
4. **CORS**: Configure appropriately for production
5. **TLS 1.2+**: Enforced on storage accounts
6. **Resource Tags**: For governance and cost management

## Cost Estimation

Typical monthly costs (may vary):

- Static Web App (Free Tier): $0
- Function App (Consumption): ~$0-20 depending on usage
- Storage Account: ~$1-5
- Application Insights: ~$0-10 depending on data volume

**Estimated Total**: $1-35/month for a development environment

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- Open a GitHub Issue
- Check Azure documentation: https://docs.microsoft.com/azure
- Terraform Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

## Additional Resources

- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Workload Identity Federation](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)

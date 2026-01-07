# Full Stack Demo - Project Structure

This document provides a complete overview of the project structure and files.

## Directory Tree

```
full-stack-demo/
├── .github/
│   └── workflows/
│       └── azure-deploy.yml         # GitHub Actions CI/CD workflow
│
├── infra/                            # Terraform Infrastructure as Code
│   ├── main.tf                       # Main infrastructure resources
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Output values
│   ├── providers.tf                  # Provider configuration
│   ├── terraform.tfvars.example      # Example variables file
│   ├── backend.hcl.example           # Example backend configuration
│   └── .gitignore                    # Terraform gitignore
│
├── frontend/                         # React Frontend Application
│   ├── public/
│   │   └── index.html                # HTML template
│   ├── src/
│   │   ├── App.js                    # Main React component
│   │   ├── App.css                   # Component styles
│   │   ├── index.js                  # React entry point
│   │   └── index.css                 # Global styles
│   ├── package.json                  # Frontend dependencies
│   └── .gitignore                    # Frontend gitignore
│
├── api/                              # Azure Functions Backend
│   ├── src/
│   │   └── functions/
│   │       ├── hello.js              # Hello world function
│   │       └── healthcheck.js        # Health check function
│   ├── host.json                     # Function app configuration
│   ├── package.json                  # Backend dependencies
│   ├── README.md                     # API documentation
│   └── .gitignore                    # API gitignore
│
├── README.md                         # Main project documentation
├── SETUP_GUIDE.md                    # Quick setup guide
├── CONTRIBUTING.md                   # Contribution guidelines
├── PROJECT_STRUCTURE.md              # This file
└── .gitignore                        # Root gitignore
```

## File Descriptions

### Root Level

| File | Purpose |
|------|---------|
| `README.md` | Comprehensive project documentation, setup instructions, architecture overview |
| `SETUP_GUIDE.md` | Quick start guide for deploying the application |
| `CONTRIBUTING.md` | Guidelines for contributors |
| `PROJECT_STRUCTURE.md` | Project structure documentation (this file) |
| `.gitignore` | Git ignore rules for the entire project |

### Infrastructure (`/infra`)

| File | Purpose |
|------|---------|
| `main.tf` | Defines all Azure resources (Resource Group, Function App, Static Web App, Storage, Application Insights) |
| `variables.tf` | Input variables for configurable values (subscription ID, location, project name, etc.) |
| `outputs.tf` | Output values (URLs, resource names, API keys) |
| `providers.tf` | Terraform and Azure provider configuration, OIDC authentication setup |
| `terraform.tfvars.example` | Example variables file - copy to terraform.tfvars and customize |
| `backend.hcl.example` | Example backend configuration for Terraform state storage |
| `.gitignore` | Ignores Terraform state files, lock files, and sensitive data |

### Frontend (`/frontend`)

| File | Purpose |
|------|---------|
| `package.json` | React dependencies, scripts for build and development |
| `public/index.html` | HTML template for React app |
| `src/App.js` | Main React component with API integration, loading states, and UI |
| `src/App.css` | Styles for the main component with gradient background |
| `src/index.js` | React entry point, renders App component |
| `src/index.css` | Global CSS reset and base styles |
| `.gitignore` | Ignores node_modules, build output, and environment files |

### Backend (`/api`)

| File | Purpose |
|------|---------|
| `package.json` | Azure Functions dependencies |
| `host.json` | Function app configuration (logging, extension bundles) |
| `src/functions/hello.js` | HTTP trigger function that returns a greeting message |
| `src/functions/healthcheck.js` | Health check endpoint for monitoring |
| `README.md` | API documentation and local development instructions |
| `.gitignore` | Ignores node_modules, local settings, and build artifacts |

### CI/CD (`.github/workflows`)

| File | Purpose |
|------|---------|
| `azure-deploy.yml` | Complete CI/CD pipeline with 4 jobs: Terraform deployment, Function deployment, Static Web App deployment, and deployment summary |

## Key Features by Component

### Infrastructure (Terraform)

- ✅ Azure Resource Group
- ✅ Storage Account for Function App
- ✅ App Service Plan (Consumption tier)
- ✅ Linux Function App with Node.js 20 runtime
- ✅ Azure Static Web App
- ✅ Application Insights for monitoring
- ✅ Function App registration with Static Web App
- ✅ OIDC authentication configuration
- ✅ Remote state management in Azure Storage

### Frontend (React)

- ✅ Modern React 18 with Hooks
- ✅ Responsive gradient UI design
- ✅ API integration with error handling
- ✅ Loading states and user feedback
- ✅ Information cards about the stack
- ✅ External documentation links

### Backend (Azure Functions)

- ✅ Azure Functions v4 programming model
- ✅ HTTP trigger functions
- ✅ Health check endpoint
- ✅ JSON responses
- ✅ Query parameter handling
- ✅ Application Insights integration

### CI/CD (GitHub Actions)

- ✅ OIDC authentication (no secrets!)
- ✅ Terraform automation (init, plan, apply)
- ✅ Parallel deployment jobs
- ✅ Deployment status summaries
- ✅ Error handling and reporting
- ✅ Manual workflow dispatch

## Infrastructure Resources Created

When deployed, the following Azure resources are created:

1. **Resource Group**: `rg-fullstackdemo-dev`
2. **Storage Account**: `stfullstackdemodev` (for Function App)
3. **App Service Plan**: `asp-fullstackdemo-dev` (Consumption/Y1)
4. **Function App**: `func-fullstackdemo-dev`
5. **Static Web App**: `swa-fullstackdemo-dev`
6. **Application Insights**: `appi-fullstackdemo-dev`

Plus:
- **Terraform State Storage**: Separate resource group and storage account

## Secrets Required

The following GitHub Secrets must be configured:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Entra ID App Registration Client ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |
| `TERRAFORM_STATE_RG` | Resource group for Terraform state |
| `TERRAFORM_STATE_STORAGE` | Storage account for Terraform state |
| `TERRAFORM_STATE_CONTAINER` | Container name for Terraform state |

## API Endpoints

Once deployed, the following endpoints are available:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/hello?name=X` | GET, POST | Returns greeting message |
| `/api/healthcheck` | GET | Returns health status |

## Development Workflow

1. **Local Development**: Edit files locally
2. **Test Locally**: Run frontend with `npm start`, functions with `npm start`
3. **Commit Changes**: Git commit and push to feature branch
4. **Pull Request**: Create PR for review
5. **Merge to Main**: Automatic deployment via GitHub Actions
6. **Monitor**: Check deployment summary and Application Insights

## Cost Breakdown

Estimated monthly costs:

- **Static Web App (Free tier)**: $0
- **Function App (Consumption)**: $0-20 (depending on usage)
- **Storage Account**: $1-5
- **Application Insights**: $0-10 (depending on data volume)
- **Terraform State Storage**: ~$1

**Total**: $1-35/month (development environment)

## Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | React | 18.x |
| Backend | Azure Functions | v4 |
| Runtime | Node.js | 20.x |
| IaC | Terraform | 1.7.0+ |
| CI/CD | GitHub Actions | Latest |
| Cloud | Microsoft Azure | Latest |
| Auth | OIDC/Workload Identity | Latest |

## Next Steps

1. Follow [SETUP_GUIDE.md](SETUP_GUIDE.md) to deploy
2. Customize the application to your needs
3. Add new features and functions
4. Deploy to production environment
5. Add custom domain and SSL
6. Implement authentication

---

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

For contributing guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md)

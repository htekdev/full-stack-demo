You are helping me build a demo full-stack application using:
- React frontend
- Azure Functions backend
- Azure Static Web App hosting
- GitHub Actions for CI/CD
- Terraform for provisioning all Azure resources
- An existing Entra ID App registration (assume it's already created; I will provide details later)

Create the following:

1. A complete Terraform configuration in an /infra folder that provisions:
   - A resource group
   - Azure Storage Account for the Function App
   - Azure Function App (Node or Python runtime)
   - Azure Static Web App resource
   - Outputs for the Function endpoint and Static Web App endpoint
   - Variables for subscription ID, location, and Entra ID app info
   - A backend configuration for Terraform state stored in Azure Storage

2. A GitHub Actions workflow named azure-deploy.yml that:
   - Triggers on push to main
   - Installs Terraform
   - Runs `terraform init/plan/apply`
   - Builds the React frontend
   - Deploys the Static Web App
   - Deploys Azure Functions
   - Uses OIDC with the Entra ID app registration to authenticate to Azure
   - Provides helpful status output for GHCP's coding agent to validate

3. Add documentation (README.md) explaining:
   - How to configure the Entra ID app for OIDC with GitHub Actions
   - Required repository secrets
   - How the deployment workflow works end to end

Follow best practices for:
- Terraform structure (modules if necessary)
- Reusable GitHub Actions steps
- Minimal manual configuration by the user
- Output clarity so a GitHub Copilot Coding Agent can validate success

Generate all files in complete form.
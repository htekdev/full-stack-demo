terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # Backend configuration should be provided via command line or backend config file
    # Example:
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "sttfstate<unique>"
    # container_name       = "tfstate"
    # key                  = "full-stack-demo.terraform.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Use Azure AD authentication for storage operations
  storage_use_azuread = true
  

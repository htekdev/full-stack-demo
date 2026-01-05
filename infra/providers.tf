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
    use_oidc = true
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Authentication via OIDC/Workload Identity Federation
  # The following will be automatically set by GitHub Actions:
  # - ARM_CLIENT_ID
  # - ARM_TENANT_ID
  # - ARM_SUBSCRIPTION_ID
  # - ARM_USE_OIDC=true
}

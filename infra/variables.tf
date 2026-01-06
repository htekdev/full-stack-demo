variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "fullstackdemo"
}

variable "entra_app_client_id" {
  description = "Entra ID App Registration Client ID"
  type        = string
  sensitive   = true
}

variable "entra_app_tenant_id" {
  description = "Entra ID Tenant ID"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "FullStackDemo"
  }
}

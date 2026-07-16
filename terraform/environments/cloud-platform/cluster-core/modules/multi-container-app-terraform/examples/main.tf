# Example: Using the Multi-Container App Terraform Module
#
# This example shows how to use the module in your own Terraform configuration.
# Create this file in a separate directory from the module.

terraform {
  required_version = ">= 1.2.5"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

# Configure the kubectl provider
# Adjust based on your cluster configuration
provider "kubectl" {
  # config_path = "~/.kube/config"
  # Or use other authentication methods
}

# Deploy the multi-container app
module "multi_container_app" {
  source = "../multi-container-app-terraform"

  # Basic configuration
  namespace = "my-multi-container-app"

  # Option 1: Deploy PostgreSQL with the app (like Helm chart)
  deploy_postgresql    = true
  postgres_database    = "my_app_db"
  postgres_username    = "appuser"
  postgres_password    = "secure-password-here"
  
  # The database secret is created automatically
  create_database_secret = true

  # Optional: Scale replicas
  content_api_replicas = 2
  rails_app_replicas   = 3
  worker_replicas      = 1

  # Optional: Use different image versions
  content_api_image_tag = "content-api-1.6"
  rails_app_image_tag   = "rails-app-1.6"
  worker_image_tag      = "worker-1.6"

  # Optional: Enable external access via HTTPRoute
  enable_httproute = true
  hostnames = [
    "my-app.example.com"
  ]

  # Optional: Disable migrations if not needed
  enable_migrations = true
}

# Outputs
output "namespace" {
  value = module.multi_container_app.namespace
}

output "content_api_url" {
  value = module.multi_container_app.content_api_service_url
}

output "rails_app_url" {
  value = module.multi_container_app.rails_app_service_url
}

output "external_urls" {
  value = module.multi_container_app.external_urls
}

# Alternative: Use external database (e.g., RDS, Cloud SQL)
# module "multi_container_app_external_db" {
#   source = "../multi-container-app-terraform"
#
#   namespace = "my-app-prod"
#
#   # Use external database
#   deploy_postgresql      = false
#   create_database_secret = true
#   database_url           = "postgresql://user:password@external-db-host:5432/production_db"
#
#   enable_httproute = true
#   hostnames = ["app.production.example.com"]
# }

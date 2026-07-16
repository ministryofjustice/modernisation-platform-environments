# Multi-Container App Terraform Module Outputs

output "namespace" {
  description = "The namespace where the application is deployed"
  value       = var.namespace
}

output "postgresql_deployed" {
  description = "Whether PostgreSQL was deployed as part of the application"
  value       = var.deploy_postgresql
}

output "postgresql_service_url" {
  description = "Internal URL for PostgreSQL service (if deployed)"
  value       = var.deploy_postgresql ? "postgresql://postgresql.${var.namespace}.svc.cluster.local:5432/${var.postgres_database}" : null
}

output "content_api_service_url" {
  description = "Internal URL for the Content API service"
  value       = "http://content-api-service.${var.namespace}.svc.cluster.local:4567"
}

output "rails_app_service_url" {
  description = "Internal URL for the Rails App service"
  value       = "http://rails-app-service.${var.namespace}.svc.cluster.local:3000"
}

output "external_urls" {
  description = "External URLs for the application (if HTTPRoute is enabled)"
  value       = var.enable_httproute ? var.hostnames : []
}

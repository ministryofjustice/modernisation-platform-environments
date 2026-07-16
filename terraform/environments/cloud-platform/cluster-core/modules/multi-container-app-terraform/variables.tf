variable "namespace" {
  type        = string
  description = "Namespace to create for the multi-container app"
  default     = "multi-container-app"
}

# Content API Configuration
variable "content_api_image_repository" {
  type        = string
  description = "Container image repository for content API"
  default     = "ministryofjustice/cloud-platform-multi-container-demo-app"
}

variable "content_api_image_tag" {
  type        = string
  description = "Container image tag for content API"
  default     = "content-api-1.6"
}

variable "content_api_replicas" {
  type        = number
  description = "Number of replicas for content API"
  default     = 1
}

# Rails App Configuration
variable "rails_app_image_repository" {
  type        = string
  description = "Container image repository for Rails app"
  default     = "ministryofjustice/cloud-platform-multi-container-demo-app"
}

variable "rails_app_image_tag" {
  type        = string
  description = "Container image tag for Rails app"
  default     = "rails-app-1.6"
}

variable "rails_app_replicas" {
  type        = number
  description = "Number of replicas for Rails app"
  default     = 1
}

# Worker Configuration
variable "worker_image_repository" {
  type        = string
  description = "Container image repository for worker"
  default     = "ministryofjustice/cloud-platform-multi-container-demo-app"
}

variable "worker_image_tag" {
  type        = string
  description = "Container image tag for worker"
  default     = "worker-1.6"
}

variable "worker_replicas" {
  type        = number
  description = "Number of replicas for worker"
  default     = 1
}

# Database Configuration
variable "database_secret_name" {
  type        = string
  description = "Name of the secret containing database credentials"
  default     = "container-database-url"
}

variable "create_database_secret" {
  type        = bool
  description = "Whether to create the database secret (set to false if managing externally)"
  default     = true
}

variable "database_url" {
  type        = string
  description = "PostgreSQL database URL (only required if create_database_secret is true and deploy_postgresql is false)"
  default     = ""
  sensitive   = true
}

# PostgreSQL Deployment (like Helm chart dependency)
variable "deploy_postgresql" {
  type        = bool
  description = "Deploy PostgreSQL as part of the application (similar to Helm chart dependency)"
  default     = true
}

variable "postgres_database" {
  type        = string
  description = "PostgreSQL database name"
  default     = "multi_container_demo_app"
}

variable "postgres_username" {
  type        = string
  description = "PostgreSQL username"
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password"
  default     = "changeme"
  sensitive   = true
}

variable "postgres_secret_name" {
  type        = string
  description = "Name of the secret for PostgreSQL credentials"
  default     = "postgresql-credentials"
}

variable "content_api_url" {
  type        = string
  description = "URL for the content API service"
  default     = "http://content-api-service:4567/image_url.json"
}

# Ingress/HTTPRoute Configuration
variable "enable_httproute" {
  type        = bool
  description = "Enable HTTPRoute for external access"
  default     = false
}

variable "listenerset_name" {
  type        = string
  description = "Name of the shared platform ListenerSet that the HTTPRoute should reference"
  default     = "default-listenerset"
}

variable "listenerset_namespace" {
  type        = string
  description = "Namespace of the shared platform ListenerSet that the HTTPRoute should reference"
  default     = "envoy-gateway-system"
}

variable "hostnames" {
  type        = list(string)
  description = "Hostnames for the HTTPRoute"
  default     = []

  validation {
    condition     = !var.enable_httproute || (length(var.hostnames) > 0 && alltrue([for hostname in var.hostnames : trimspace(hostname) != ""]))
    error_message = "hostnames must contain at least one non-empty hostname when enable_httproute is true."
  }
}

# Migrations Configuration
variable "enable_migrations" {
  type        = bool
  description = "Enable database migrations job"
  default     = true
}

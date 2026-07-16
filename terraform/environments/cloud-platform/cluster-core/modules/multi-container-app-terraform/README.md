# Multi-Container App Terraform Module

This Terraform module deploys a multi-container application to Kubernetes, abstracting away the complexity of Helm charts into a simpler, more maintainable infrastructure-as-code approach.

## Architecture

The module deploys three main components:

1. **Content API**: A microservice that provides content data
2. **Rails App**: The main web application with database connectivity
3. **Worker**: A background worker for async tasks

## Components Deployed

- **Namespace**: Isolated Kubernetes namespace with pod security enforcement
- **Content API Deployment & Service**: Content API service on port 4567
- **Rails App Deployment & Service**: Main web application on port 3000
- **Worker Deployment**: Background worker process
- **Migrations Job**: Optional database migration job
- **HTTPRoute**: Optional external access using Gateway API

## Prerequisites

- Terraform >= 1.2.5
- Kubernetes cluster with Gateway API support (if using HTTPRoute)
- PostgreSQL database OR use the built-in PostgreSQL deployment
- kubectl provider configured

## Usage

### Basic Example (with built-in PostgreSQL)

Like the original Helm chart, the module can deploy PostgreSQL for you:

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Deploy PostgreSQL with the app (like Helm chart dependency)
  deploy_postgresql = true
  postgres_database = "my_app_db"
  postgres_username = "appuser"
  postgres_password = "secure-password"
  
  # Optionally customize image tags
  content_api_image_tag = "content-api-1.7"
  rails_app_image_tag   = "rails-app-1.7"
  worker_image_tag      = "worker-1.7"
}
```

### Using External Database (Production)

For production, use a managed database service:

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Use external database (RDS, Cloud SQL, etc.)
  deploy_postgresql = false
  database_url      = "postgresql://user:password@rds-host:5432/production_db"
  
  # Optionally customize image tags
  content_api_image_tag = "content-api-1.7"
  rails_app_image_tag   = "rails-app-1.7"
  worker_image_tag      = "worker-1.7"
}
```

### Using Existing Database Secret

If you manage secrets externally (e.g., using Sealed Secrets, External Secrets Operator):

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Use existing secret (managed externally)
  create_database_secret = false
  database_secret_name   = "my-existing-database-secret"
  
  # Optionally customize image tags
  content_api_image_tag = "content-api-1.7"
  rails_app_image_tag   = "rails-app-1.7"
  worker_image_tag      = "worker-1.7"
}
```

### With HTTPRoute for External Access

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Deploy PostgreSQL with the app
  deploy_postgresql = true
  postgres_database = "my_app_db"
  postgres_username = "appuser"
  postgres_password = "secure-password"
  
  # Enable external access
  enable_httproute = true
  hostnames = [
    "my-app.apps.live.cloud-platform.service.justice.gov.uk"
  ]
  
  # Optional: customize ListenerSet
  listenerset_name      = "default-listenerset"
  listenerset_namespace = "envoy-gateway-system"
}
```

### Custom Replicas and Images

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Scale up replicas
  content_api_replicas = 3
  rails_app_replicas   = 5
  worker_replicas      = 2
  
  # Use custom images
  content_api_image_repository = "my-registry/content-api"
  content_api_image_tag        = "v2.0"
  rails_app_image_repository   = "my-registry/rails-app"
  rails_app_image_tag          = "v2.0"
  worker_image_repository      = "my-registry/worker"
  worker_image_tag             = "v2.0"
  
  database_secret_name = "my-database-url"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace | Namespace to create for the multi-container app | string | "multi-container-app" | no |
| content_api_image_repository | Container image repository for content API | string | "ministryofjustice/cloud-platform-multi-container-demo-app" | no |
| content_api_image_tag | Container image tag for content API | string | "content-api-1.6" | no |
| content_api_replicas | Number of replicas for content API | number | 1 | no |
| rails_app_image_repository | Container image repository for Rails app | string | "ministryofjustice/cloud-platform-multi-container-demo-app" | no |
| rails_app_image_tag | Container image tag for Rails app | string | "rails-app-1.6" | no |
| rails_app_replicas | Number of replicas for Rails app | number | 1 | no |
| worker_image_repository | Container image repository for worker | string | "ministryofjustice/cloud-platform-multi-container-demo-app" | no |
| worker_image_tag | Container image tag for worker | string | "worker-1.6" | no |
| worker_replicas | Number of replicas for worker | number | 1 | no |
| database_secret_name | Name of the secret containing database credentials | string | "container-database-url" | no |
| create_database_secret | Whether to create the database secret (set to false if managing externally) | bool | true | no |
| deploy_postgresql | Deploy PostgreSQL as part of the application (similar to Helm chart) | bool | true | no |
| postgres_database | PostgreSQL database name | string | "multi_container_demo_app" | no |
| postgres_username | PostgreSQL username | string | "postgres" | no |
| postgres_password | PostgreSQL password | string | "changeme" | no |
| postgres_secret_name | Name of the secret for PostgreSQL credentials | string | "postgresql-credentials" | no |
| database_url | PostgreSQL database URL (required if deploy_postgresql is false) | string | "" | conditional |
| content_api_url | URL for the content API service | string | "http://content-api-service:4567/image_url.json" | no |
| enable_httproute | Enable HTTPRoute for external access | bool | false | no |
| listenerset_name | Name of the shared platform ListenerSet | string | "default-listenerset" | no |
| listenerset_namespace | Namespace of the shared platform ListenerSet | string | "envoy-gateway-system" | no |
| hostnames | Hdeploy PostgreSQL or use an external database.

### Option 1: Deploy PostgreSQL with the App (Like Helm Chart)

Set `deploy_postgresql = true` (this is the default):

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"
  
  deploy_postgresql = true
  postgres_database = "my_app_db"
  postgres_username = "appuser"
  postgres_password = "secure-password"
}
```

This deploys PostgreSQL similar to the Helm chart's dependency. The database URL is automatically constructed.

**⚠️ Note:** This uses `emptyDir` storage (non-persistent). For production, use an external managed database.

### Option 2: Use External Database (Recommended for Production)

Set `deploy_postgresql = false` and provide the `database_url`:

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"
  
  deploy_postgresql = false
  database_url      = "postgresql://user:password@rds-host:5432/production_db"
}
```

### Option 3: External Secret Management
  database_url           = "postgresql://user:password@host:5432/database"
}
```

### Option 2: External Secret Management (Recommended for Production)

For production environments, manage secrets externally using tools like:
- Sealed Secrets
- External Secrets Operator
- HashiCorp Vault
- Cloud provider secret managers

Set `create_database_secret = false`:

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"
  
  create_database_secret = false
  database_secret_name   = "my-externally-managed-secret"
}
```

Then create the secret manually:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: container-database-url
  namespace: my-app
type: Opaque
stringData:
  url: "postgresql://user:password@host:5432/database"
```

Or with kubectl:

```bash
kubectl create secret generic container-database-url \
  --from-literal=url='postgresql://user:password@host:5432/database' \
  --namespace=my-app
```

## Security

All containers are configured with:
- Pod Security Standard: Restricted
- Non-root user execution
- No privilege escalation
- Dropped all capabilities
- RuntimeDefault seccomp profile

## Migration from Helm

This module replaces the Helm chart deployment with the following benefits:

1. **Simpler Configuration**: All configuration in one place (variables.tf)
2. **Infrastructure as Code**: Native Terraform state management
3. **Better Integration**: Easier to integrate with other Terraform resources
4. **Version Control**: Clearer tracking of infrastructure changes
5. **Reduced Dependencies**: No Helm or Tiller required

### Key Differences from Helm Chart

- PostgreSQL is **not** included - manage database separately
- Uses HTTPRoute instead of Ingress (more modern Gateway API)
- Security contexts are enforced by default
- Simpler value structure

## Outputs

The module doesn't currently define outputs, but you can extend it to output:
- Service URLs
- Namespace name
- Deployment status

## License

See parent repository LICENSE file.

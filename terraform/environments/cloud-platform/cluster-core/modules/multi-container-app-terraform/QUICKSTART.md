# Quick Start Guide

Get the multi-container app running with Terraform in 5 minutes.

## Prerequisites

- Terraform >= 1.2.5 installed
- kubectl configured with access to your Kubernetes cluster

## Step 1: Configure Provider

Create a `provider.tf` file in a new directory:

```hcl
terraform {
  required_version = ">= 1.2.5"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}
```

## Step 2: Use the Module

Create a `main.tf` file:

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  # Database configuration - Terraform will create the secret
  creeploy PostgreSQL with the app (like Helm chart)
  deploy_postgresql = true
  postgres_database = "my_app_db"
  postgres_username = "appuser"
  postgres_password = "secure-password
  # Optional: enable external access
  enable_httproute = true
  hostnames = [
    "my-app.example.com"
  ]
}

output "namespace" {
  value = module.multi_container_app.namespace
}
```

## Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted.

## Step 4: Verify

```bash
# Check pods
kubectl get pods -n my-app

# Expected output:
# NAME                           READY   STATUS    RESTARTS   AGE
# content-api-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
# rails-app-xxxxxxxxxx-xxxxx     1/1     Running   0          1m
# worker-xxxxxxxxxx-xxxxx        1/1     Running   0          1m

# Check services
kubectl get svc -n my-app

# Check HTTPRoute (if enabled)
kubectl get httproute -n my-app
```

## Step 5: Access the Application

If HTTPRoute is enabled:
```bash
curl https://my-app.example.com
```

Or port-forward for testing:
```bash
kubectl port-forward -n my-app svc/rails-app-service 3000:3000
curl http://localhost:3000
```

## Common Customizations

### Scale Replicas

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  content_api_replicas = 3
  rails_app_replicas   = 5
  worker_replicas      = 2
}
```

### Use Different Images

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace = "my-app"
  
  content_api_image_tag = "content-api-2.0"
  rails_app_image_tag   = "rails-app-2.0"
  worker_image_tag      = "worker-2.0"
}
```

### Disable Migrations

```hcl
module "multi_container_app" {
  source = "./multi-container-app-terraform"

  namespace         = "my-app"
  enable_migrations = false
}
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Troubleshooting

### Pods not starting?

```bash
# Check pod status
kubectl describe pod <pod-name> -n my-app

# Check logs
kubectl logs <pod-name> -n my-app
```

### Database connection issues?

```bash
# Verify secret exists
kubectl get secret container-database-url -n my-app

# Check secret value
kubectl get secret container-database-url -n my-app \
  -o jsonpath='{.data.url}' | base64 -d
```

### HTTPRoute not working?

```bash
# Check HTTPRoute status
kubectl describe httproute -n my-app

# Verify ListenerSet exists
kubectl get listenerset -n envoy-gateway-system
```

## Next Steps

- Review [README.md](README.md) for detailed documentation
- Check [COMPARISON.md](COMPARISON.md) to understand benefits
- Read [MIGRATION.md](MIGRATION.md) if migrating from Helm
- Explore [examples/](examples/) for advanced usage

## Getting Help

- Check Terraform plan output for issues
- Review kubectl events: `kubectl get events -n my-app`
- Verify resource status: `terraform show`
- Check provider documentation: https://registry.terraform.io/providers/alekc/kubectl/

## What Gets Deployed?

✅ Kubernetes Namespace  
✅ Content API (Deployment + Service)  
✅ Rails App (Deployment + Service)  
✅ Worker (Deployment)  
✅ Database Migrations Job  
✅ HTTPRoute (optional, for external access)  

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│           Kubernetes Cluster                │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Namespace: my-app                  │   │
│  │                                     │   │
│  │  ┌──────────────┐  ┌──────────┐   │   │
│  │  │ Content API  │  │ Service  │   │   │
│  │  │  Deployment  ├──┤ :4567    │   │   │
│  │  └──────────────┘  └──────────┘   │   │
│  │                                     │   │
│  │  ┌──────────────┐  ┌──────────┐   │   │
│  │  │  Rails App   │  │ Service  │   │   │
│  │  │  Deployment  ├──┤ :3000    ├───┼───┼──► HTTPRoute
│  │  └──────┬───────┘  └──────────┘   │   │
│  │         │                          │   │
│  │         │ DATABASE_URL             │   │
│  │         ↓                          │   │
│  │  ┌──────────────┐                 │   │
│  │  │   Worker     │                 │   │
│  │  │  Deployment  │                 │   │
│  │  └──────┬───────┘                 │   │
│  │         │                          │   │
│  │         │ DATABASE_URL             │   │
│  │         ↓                          │   │
│  │  ┌──────────────┐                 │   │
│  │  │ Migrations   │                 │   │
│  │  │     Job      │                 │   │
│  │  └──────────────┘                 │   │
│  │                                     │   │
│  └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
                    │
                    ↓
            External Database
         (Managed separately)
```

That's it! You now have a fully functional multi-container application deployed via Terraform.

# Migration Guide: Helm to Terraform

This guide helps you migrate from the Helm chart deployment to the Terraform module.

## Overview

The Terraform module provides a simpler, more maintainable way to deploy the multi-container application without requiring Helm.

## Key Differences

### What's Included

| Component | Helm Chart | Terraform Module |
|-----------|------------|------------------|
| Content API | ✅ | ✅ |
| Rails App | ✅ | ✅ |
| Worker | ✅ | ✅ |
| PostgreSQL Database | ✅ (via subchart) | ❌ (manage separately) |
| Ingress | ✅ | ❌ (use HTTPRoute) |
| HTTPRoute | ❌ | ✅ |
| Migrations Job | ✅ | ✅ |

### Configuration Comparison

**Helm `values.yaml`:**
```yaml
contentapi:
  replicaCount: 1
  image:
    repository: ministryofjustice/cloud-platform-multi-container-demo-app
    tag: content-api-1.6
    pullPolicy: IfNotPresent
```

**Terraform `terraform.tfvars`:**
```hcl
content_api_replicas         = 1
content_api_image_repository = "ministryofjustice/cloud-platform-multi-container-demo-app"
content_api_image_tag        = "content-api-1.6"
```

## Migration Steps

### Step 1: Backup Current Configuration

```bash
# Export current Helm values
helm get values <release-name> > current-values.yaml

# Save current resource state
kubectl get all -n <namespace> -o yaml > current-state.yaml
```

### Step 2: Set Up Database Separately

Since the Terraform module doesn't include PostgreSQL, you need to manage it separately:

**Option A: Use existing PostgreSQL**
```bash
# Get current database credentials
kubectl get secret container-postgres-secrets -n <namespace> -o yaml > postgres-secret.yaml

# Keep the database running or migrate to a managed service
```

**Option B: Deploy PostgreSQL separately**
```hcl
# Use a separate Terraform module for PostgreSQL
module "postgresql" {
  source = "path/to/postgresql-module"
  # ... configuration
}

# Or use a managed service like RDS, Cloud SQL, etc.
```

### Step 3: Create Database Secret

Ensure the database URL secret exists in your namespace:

```bash
kubectl create secret generic container-database-url \
  --from-literal=url='postgresql://user:password@host:5432/database' \
  --namespace=<your-namespace>
```

### Step 4: Convert Helm Values to Terraform Variables

Create a `terraform.tfvars` file based on your Helm values:

```hcl
namespace = "<your-namespace>"

# Convert image configurations
content_api_image_tag = "<from-values.contentapi.image.tag>"
rails_app_image_tag   = "<from-values.railsapp.image.tag>"
worker_image_tag      = "<from-values.worker.image.tag>"

# Convert replica counts
content_api_replicas = <from-values.contentapi.replicaCount>
rails_app_replicas   = <from-values.railsapp.replicaCount>
worker_replicas      = <from-values.worker.replicaCount>

# Convert ingress to HTTPRoute
enable_httproute = true
hostnames = [
  "<from-values.ingress.hosts[].host>"
]
```

### Step 5: Initialize Terraform

```bash
cd multi-container-app-terraform
terraform init
```

### Step 6: Plan the Migration

Review what Terraform will create:

```bash
terraform plan
```

**Expected changes:**
- New namespace (or import existing)
- New deployments (similar to existing)
- New services (similar to existing)
- New HTTPRoute (replacing Ingress)

### Step 7: Import Existing Resources (Optional)

If you want to avoid downtime, import existing resources:

```bash
# Import namespace
terraform import 'kubectl_manifest.namespace' <namespace-yaml>

# Import deployments
terraform import 'kubectl_manifest.content_api_deployment' <deployment-yaml>
terraform import 'kubectl_manifest.rails_app_deployment' <deployment-yaml>
terraform import 'kubectl_manifest.worker_deployment' <deployment-yaml>

# Import services
terraform import 'kubectl_manifest.content_api_service' <service-yaml>
terraform import 'kubectl_manifest.rails_app_service' <service-yaml>
```

> **Note:** The kubectl provider import process can be complex. Alternatively, consider a blue-green deployment approach.

### Step 8: Deploy with Terraform

```bash
terraform apply
```

### Step 9: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n <namespace>

# Check services
kubectl get svc -n <namespace>

# Check HTTPRoute (if enabled)
kubectl get httproute -n <namespace>

# Test the application
curl https://<your-hostname>/
```

### Step 10: Remove Helm Release

Once verified, remove the Helm release:

```bash
# Uninstall Helm release
helm uninstall <release-name> -n <namespace>

# Or, if you want to keep resources:
helm uninstall <release-name> -n <namespace> --keep-history
```

## Blue-Green Migration (Recommended for Production)

For zero-downtime migration:

1. Deploy Terraform module to a **new namespace**:
   ```hcl
   namespace = "multi-container-app-v2"
   ```

2. Configure HTTPRoute with new hostname or use traffic splitting

3. Test thoroughly in the new namespace

4. Update DNS or traffic routing to point to new namespace

5. Monitor for issues

6. Decommission old Helm deployment after verification

## Rollback Plan

If issues occur:

1. **Keep Helm release** until Terraform deployment is verified
2. **Backup database** before migration
3. **Document Helm values** for quick restoration
4. **Keep DNS** pointing to Helm deployment until fully tested

To rollback:
```bash
# Destroy Terraform resources
terraform destroy

# Reinstall Helm chart
helm upgrade --install <release-name> ./multi-container-app \
  -f <backup-values.yaml> \
  -n <namespace>
```

## Post-Migration Checklist

- [ ] All pods are running and healthy
- [ ] Services are accessible internally
- [ ] HTTPRoute is configured and accessible externally
- [ ] Database connectivity is working
- [ ] Migrations have run successfully
- [ ] Application functionality is verified
- [ ] Monitoring and logging are working
- [ ] Secrets are properly configured
- [ ] Helm release is removed (after verification period)
- [ ] Documentation is updated

## Troubleshooting

### Issue: Pods not starting

**Check:**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Common causes:**
- Image pull errors
- Database secret not found
- Incorrect environment variables

### Issue: Database connection failures

**Check:**
```bash
# Verify secret exists
kubectl get secret container-database-url -n <namespace>

# Check secret contents
kubectl get secret container-database-url -n <namespace> -o jsonpath='{.data.url}' | base64 -d
```

### Issue: HTTPRoute not working

**Check:**
```bash
# Verify HTTPRoute status
kubectl get httproute -n <namespace> -o yaml

# Check ListenerSet exists
kubectl get listenerset -n envoy-gateway-system
```

## Benefits After Migration

1. **Simplified Configuration**: All infrastructure in Terraform
2. **Better State Management**: Terraform state tracking
3. **Easier CI/CD Integration**: Standard Terraform workflows
4. **More Control**: Direct Kubernetes manifest control
5. **Modern Patterns**: Gateway API instead of Ingress
6. **Security**: Enforced pod security standards

## Support

For issues or questions:
- Check the [README.md](README.md) for usage examples
- Review Terraform plan output carefully
- Test in a non-production environment first
- Keep backups of all configurations

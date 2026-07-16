# Helm vs Terraform Comparison

This document provides a side-by-side comparison of deploying the multi-container app using Helm versus Terraform.

## Quick Comparison

| Aspect | Helm Chart | Terraform Module |
|--------|------------|------------------|
| **Complexity** | High (templates, helpers, values) | Low (straightforward manifests) |
| **Dependencies** | Helm CLI, Tiller (v2) | Terraform CLI only |
| **State Management** | Limited (release history) | Full (Terraform state) |
| **Configuration** | values.yaml | terraform.tfvars |
| **Templating** | Go templates | HCL + Terraform templates |
| **Database** | Included (subchart) | Included (optional deployment) |
| **Integration** | Standalone | Native Terraform ecosystem |
| **Version Control** | Charts + values | Pure IaC |
| **Testing** | helm test | terraform plan |
| **Rollback** | helm rollback | terraform state |

## File Structure Comparison

### Helm Chart Structure
```
multi-container-app/
├── Chart.yaml                          # Chart metadata
├── values.yaml                         # Default values (100+ lines)
├── requirements.yaml                   # Dependencies (PostgreSQL)
├── container-postgres-secrets.yaml     # Secret template
├── charts/                             # Dependency charts
│   └── postgresql/
└── templates/
    ├── _helpers.tpl                    # Template helpers
    ├── NOTES.txt                       # Post-install notes
    ├── content-api/
    │   ├── deployment.yaml
    │   └── service.yaml
    ├── rails-app/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── ingress.yaml
    │   └── migrations-job.yaml
    └── worker/
        └── deployment.yaml
```

### Terraform Module Structure
```
multi-container-app-terraform/
├── main.tf                             # Resource definitions
├── variables.tf                        # Input variables
├── outputs.tf                          # Output values
├── versions.tf                         # Provider requirements
├── terraform.tfvars.example            # Example configuration
├── .gitignore                          # Git ignore rules
├── README.md                           # Documentation
├── MIGRATION.md                        # Migration guide
├── manifests/
│   ├── namespace.yaml
│   ├── database-secret.yaml
│   ├── postgresql-deployment.yaml
│   ├── postgresql-service.yaml
│   ├── postgresql-secret.yaml
│   ├── content-api-deployment.yaml
│   ├── content-api-service.yaml
│   ├── rails-app-deployment.yaml
│   ├── rails-app-service.yaml
│   ├── worker-deployment.yaml
│   ├── migrations-job.yaml
│   └── http-route.yaml
└── examples/
    └── main.tf                         # Usage example
```

## Configuration Comparison

### Helm: values.yaml (excerpt)
```yaml
databaseUrlSecretName: container-database-url
contentapiurl: "http://content-api-service:4567/image_url.json"
                
ingress:
  enabled: true
  annotations:
    kubernetes.io/tls-acme: "true"
  className: ""
  hosts:
    - host: mcda-starter-pack-2.apps.cp-0104-1339.cloud-platform.service.justice.gov.uk
      paths: []

postgresql:
  enabled: true
  existingSecret: container-postgres-secrets
  postgresqlDatabase: multi_container_demo_app
  persistence:
    enabled: false

contentapi:
  replicaCount: 1
  image:
    repository: ministryofjustice/cloud-platform-multi-container-demo-app
    tag: content-api-1.6
    pullPolicy: IfNotPresent
  containerPort: 4567
  imagePullSecrets: []
  nameOverride: ""
  fullnameOverride: ""
  service:
    type: ClusterIP
    port: 4567
    targetPort: 4567

railsapp:
  replicaCount: 1
  image:
    repository: ministryofjustice/cloud-platform-multi-container-demo-app
    tag: rails-app-1.6
    pullPolicy: IfNotPresent
  containerPort: 3000
  # ... more configuration
```

### Terraform: terraform.tfvars
```hcl
namespace = "multi-container-app"

# Content API
content_api_replicas = 1
content_api_image_tag = "content-api-1.6"

# Rails App
rails_app_replicas = 1
rails_app_image_tag = "rails-app-1.6"

# Worker
worker_replicas = 1
worker_image_tag = "worker-1.6"

# Database - Deploy PostgreSQL with the app
deploy_postgresql = true
postgres_database = "multi_container_demo_app"
postgres_username = "postgres"
postgres_password = "secure-password"

# External Access
enable_httproute = true
hostnames = [
  "my-app.apps.live.cloud-platform.service.justice.gov.uk"
]
```

## Deployment Comparison

### Helm Deployment
```bash
# Install/upgrade
helm upgrade --install multi-container-app ./multi-container-app \
  --values values.yaml \
  --namespace my-namespace \
  --create-namespace

# Check status
helm status multi-container-app -n my-namespace

# View values
helm get values multi-container-app -n my-namespace

# Rollback
helm rollback multi-container-app 1 -n my-namespace

# Uninstall
helm uninstall multi-container-app -n my-namespace
```

### Terraform Deployment
```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Check state
terraform show

# Destroy
terraform destroy
```

## Template Comparison

### Helm Template: deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-api
spec:
  replicas: {{ .Values.contentapi.replicaCount }}
  selector:
    matchLabels:
      app: content-api
  template:
    metadata:
      labels:
        app: content-api
    spec:
      containers:
        - name: content-api
          image: "{{ .Values.contentapi.image.repository }}:{{ .Values.contentapi.image.tag }}"
          imagePullPolicy: {{ .Values.contentapi.image.pullPolicy }}
          ports:
          - containerPort: {{ .Values.contentapi.containerPort }}
```

### Terraform Template: content-api-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-api
  namespace: ${namespace}
  labels:
    app: content-api
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: content-api
  template:
    metadata:
      labels:
        app: content-api
    spec:
      containers:
        - name: content-api
          image: ${image_repository}:${image_tag}
          imagePullPolicy: IfNotPresent
          securityContext:
            seccompProfile:
              type: RuntimeDefault
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          ports:
            - containerPort: 4567
              protocol: TCP
```

## Advantages of Each Approach

### Helm Advantages

✅ **Package Management**: Built-in chart versioning and distribution  
✅ **Ecosystem**: Large library of community charts  
✅ **Hooks**: Lifecycle hooks for complex operations  
✅ **Subchart Dependencies**: Easy dependency management  
✅ **Rollback**: Native rollback functionality  
✅ **Templates**: Powerful Go templating  

### Terraform Advantages

✅ **Unified IaC**: Manage Kubernetes alongside cloud resources  
✅ **State Management**: Comprehensive state tracking  
✅ **Plan Preview**: Clear preview of changes  
✅ **Simpler Syntax**: HCL is more readable than Go templates  
✅ **Native Integration**: Works with existing Terraform workflows  
✅ **Better Control**: Direct manifest control  
✅ **Security**: Enforced security contexts  
✅ **Modern Patterns**: Gateway API support  

## When to Use Each

### Use Helm When:
- You need to package and distribute applications
- You rely heavily on community charts
- You need complex lifecycle hooks
- You want built-in rollback functionality
- Your team is already Helm-centric
- You need to manage chart dependencies

### Use Terraform When:
- You manage infrastructure as code with Terraform
- You want simpler, more maintainable configurations
- You need to integrate Kubernetes with cloud resources
- You prefer declarative state management
- You want better security defaults
- You're adopting modern patterns (Gateway API)
- You want clearer change previews

## Complexity Analysis

### Lines of Configuration

**Helm:**
- Chart.yaml: 5 lines
- values.yaml: ~80 lines
- Templates: ~150 lines
- Helpers: ~30 lines
- **Total: ~265 lines**

**Terraform:**
- main.tf: ~120 lines
- variables.tf: ~110 lines
- outputs.tf: ~20 lines
- versions.tf: ~10 lines
- Manifests: ~180 lines
- **Total: ~440 lines**

> **Note:** While Terraform has more lines, they're more explicit and easier to understand. Helm's complexity is hidden in template logic.

### Cognitive Load

**Helm:**
- Learn Go templating syntax
- Understand Chart structure
- Navigate complex value hierarchies
- Debug template rendering
- Manage chart dependencies

**Terraform:**
- Learn HCL syntax (simpler than Go templates)
- Understand Terraform state
- Read straightforward manifests
- Use clear variable system

## Performance Comparison

| Operation | Helm | Terraform |
|-----------|------|-----------|
| Initial deployment | ~30s | ~45s |
| Update deployment | ~20s | ~30s |
| Plan/Diff | helm diff (plugin) | terraform plan (native) |
| Rollback | ~15s | Manual (or workspace) |
| State query | Limited | Comprehensive |

## CI/CD Integration

### Helm in CI/CD
```yaml
- name: Deploy with Helm
  run: |
    helm upgrade --install multi-container-app ./multi-container-app \
      --values values.yaml \
      --set image.tag=${{ github.sha }} \
      --namespace production
```

### Terraform in CI/CD
```yaml
- name: Terraform Plan
  run: terraform plan -out=tfplan

- name: Terraform Apply
  run: terraform apply tfplan
  if: github.ref == 'refs/heads/main'
```

## Conclusion

Both approaches have merits:

- **Helm** is ideal for packaging and distributing applications
- **Terraform** is better for infrastructure-as-code workflows

For the multi-container app specifically, **Terraform offers**:
- Simpler configuration
- Better integration with other infrastructure
- Clearer change management
- Modern Kubernetes patterns
- Enforced security standards

Choose based on your team's expertise and existing toolchain.

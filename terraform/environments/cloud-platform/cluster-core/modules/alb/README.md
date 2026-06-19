# ALB Ingress Module (EKS Auto Mode)

This module creates a Kubernetes Ingress resource that uses the AWS Load Balancer Controller (managed by EKS Auto Mode) to provision an Application Load Balancer (ALB) forwarding traffic to an Envoy Gateway service.

## Features

- Creates IngressClassParams and IngressClass for AWS Load Balancer Controller
- Provisions ALB via Kubernetes Ingress with AWS annotations
- HTTPS listener (port 443) with ACM certificate
- HTTP listener (port 80) with optional redirect to HTTPS
- Automatic target group configuration for Envoy Gateway service
- Internet-facing or internal ALB support

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix    = "my-cluster"
  certificate_arn = module.acm.certificate_arn

  envoy_service_name = module.envoy_gateway.service_name
  envoy_namespace    = module.envoy_gateway.namespace
  envoy_service_port = 80

  scheme                 = "internet-facing"
  redirect_http_to_https = true

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## How It Works

1. **IngressClassParams**: Defines AWS-specific configuration (scheme, tags) and namespace restrictions
2. **IngressClass**: Links to the EKS Auto Mode Load Balancer Controller and references params
3. **Ingress**: Minimal annotations, inherits config from IngressClassParams

The AWS Load Balancer Controller (managed by EKS Auto Mode) watches the Ingress resource and:
- Creates the ALB in AWS
- Configures listeners (HTTP:80, HTTPS:443)
- Sets up target groups pointing to Envoy service pods
- Manages security groups
- Automatically selects appropriate subnets

**Namespace Restrictions**: When `namespace_selector` is configured, only namespaces matching the selector can create Ingresses using this IngressClass. This prevents tenants from bypassing Envoy Gateway. The namespace selector is automatically set to match the `envoy_namespace` variable.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| certificate_arn | ARN of the ACM certificate for HTTPS listener | `string` | n/a | yes |
| envoy_service_name | Name of the Envoy Gateway service | `string` | n/a | yes |
| envoy_namespace | Kubernetes namespace where Envoy service is deployed | `string` | n/a | yes |
| ingress_class_name | Name of the Ingress class | `string` | `"alb"` | no |
| scheme | ALB scheme - internet-facing or internal (configured in IngressClassParams) | `string` | `"internet-facing"` | no |
| envoy_service_port | Port number of the Envoy service | `number` | `80` | no |
| health_check_path | Path for ALB health checks | `string` | `"/"` | no |
| redirect_http_to_https | Whether to redirect HTTP traffic to HTTPS | `bool` | `true` | no |
| tags | Tags to apply to the ALB (configured in IngressClassParams) | `map(string)` | `{}` | no |
| labels | Kubernetes labels to apply to Ingress resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| ingress_name | Name of the Ingress resource |
| ingress_namespace | Namespace of the Ingress resource |
| ingress_class_name | Name of the Ingress class |
| alb_dns_name | DNS name of the ALB (available after provisioning) |

## Key Configuration

**IngressClassParams (cluster-level defaults):**
- `scheme`: internet-facing or internal
- `tags`: AWS resource tags
- `namespaceSelector`: Automatically restricted to the `envoy_namespace` (prevents tenant bypass)

**Ingress annotations (per-Ingress config):**
- `alb.ingress.kubernetes.io/target-type`: Set to "ip" for direct pod targeting
- `alb.ingress.kubernetes.io/healthcheck-path`: Health check endpoint
- `alb.ingress.kubernetes.io/certificate-arn`: ACM certificate for HTTPS
- `alb.ingress.kubernetes.io/listen-ports`: Configure HTTP:80 and HTTPS:443
- `alb.ingress.kubernetes.io/ssl-redirect`: Redirect HTTP to HTTPS

## Namespace Restrictions (Shared Tenancy)

The IngressClass is automatically restricted to the namespace specified in `envoy_namespace` using the namespace's default label `kubernetes.io/metadata.name`. This prevents tenants from creating Ingresses that bypass Envoy Gateway.

**How it works:**
- IngressClassParams includes: `namespaceSelector.matchLabels["kubernetes.io/metadata.name"] = var.envoy_namespace`
- Only that specific namespace can create Ingresses using this IngressClass
- Tenants must use Gateway API (HTTPRoute) for their applications

## Notes

- **EKS Auto Mode specific**: This module uses the controller identifier `eks.amazonaws.com/alb` and IngressClassParams API `eks.amazonaws.com/v1` which are specific to EKS Auto Mode
- For **standalone AWS Load Balancer Controller**, use `ingress.k8s.aws/alb` and `elbv2.k8s.aws/v1beta1` instead
- The ALB is created and managed automatically by EKS Auto Mode's built-in Load Balancer Controller
- Target type is "ip", so the ALB targets Envoy pod IPs directly (no NodePort required)
- EKS Auto Mode automatically selects appropriate subnets based on tags and availability zones
- The ALB DNS name is available in the Ingress status after provisioning (check `module.alb.alb_dns_name`)
- Health checks default to "/" but can be customized per Envoy Gateway requirements
- HTTP to HTTPS redirect is enabled by default for security
- **Shared tenancy**: IngressClass is automatically restricted to the Envoy Gateway namespace only
- Tenants should use Gateway API (HTTPRoute) instead of creating their own Ingresses

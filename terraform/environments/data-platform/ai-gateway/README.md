# AI Gateway

> This document describes the intended architecture and operational model for the AI Gateway component. Configuration values such as instance sizes, replica counts, engine versions, scaling limits, retention periods, and other implementation details may change over time. The Terraform and Helm configuration within this directory are the source of truth.
>
> **Accurate at time of writing:** 03-06-2026

This component builds the AI Gateway platform within the Data Platform. In terms of the Modernisation Platform Environments this includes:

- Creation of the `ai-gateway` component (replacing `llm-gateway`)
- Updates to the `cluster` component to support networking requirements

The Terraform approach used throughout the Data Platform has been adopted here. Where possible, community-maintained `terraform-aws-modules` are used to provide consistency with existing Data Platform infrastructure.

---

## Architecture Overview

The AI Gateway provides a centrally managed LiteLLM deployment running on the Data Platform EKS cluster.

The platform consists of:

- LiteLLM API deployment for model inference traffic
- LiteLLM Admin deployment for platform administration
- Aurora PostgreSQL for persistent application state
- ElastiCache (Valkey) for cross-replica coordination
- AWS Application Load Balancer (ALB) using Kubernetes Gateway API
- AWS WAF for ingress protection
- Microsoft Entra ID for administrator authentication
- AWS Secrets Manager and External Secrets for secret distribution

---

## Aurora PostgreSQL

Aurora PostgreSQL serves as the primary database for LiteLLM.

### Purpose

Aurora stores:

- LiteLLM configuration
- Virtual key management
- User and team metadata
- Audit and operational data

### Security

- Encryption at rest using a dedicated KMS key
- Database credentials generated and managed through Terraform
- Deployment into private EKS data subnets
- Network access restricted to workloads within the platform VPC

### Resilience

Environment-specific backup, deletion protection and recovery settings are applied according to platform requirements.

### Observability

CloudWatch log exports are enabled to support operational troubleshooting and monitoring.

### Credentials

Connection details are stored in AWS Secrets Manager and synchronised into Kubernetes using External Secrets.

### IAM Database Authentication

IAM database authentication is currently out of scope as there are limited benefits compared with the existing approach.

---

## ElastiCache (Valkey)

LiteLLM uses ElastiCache (Valkey) as a shared coordination layer between application replicas.

### Purpose

Valkey is used for:

- Cross-replica router coordination
- Shared runtime state
- Internal LiteLLM coordination requirements

Response caching is intentionally disabled.

### Security

- Encryption at rest
- TLS encryption in transit
- Authentication via Secrets Manager managed credentials
- Deployment into private EKS data subnets
- Access restricted to workloads within the platform VPC

### Secrets

Connection information is published to AWS Secrets Manager and synchronised into Kubernetes using External Secrets.

---

## LiteLLM Deployments

LiteLLM is deployed as two independent Helm releases within the same namespace.

### API Deployment

Responsible for:

- Model inference requests
- Customer application traffic
- Database migrations

### Admin Deployment

Responsible for:

- Platform administration
- User and key management
- Operational configuration

The Admin deployment shares the same database as the API deployment but does not perform schema migrations.

### Scaling

The API deployment supports horizontal scaling through Kubernetes Horizontal Pod Autoscaling (HPA).

The Admin deployment is intentionally kept as a low-volume administrative workload.

---

## Networking

The AI Gateway uses the Kubernetes Gateway API with the `aws-alb` GatewayClass to provision an internet-facing AWS Application Load Balancer.

### Traffic Flow

```text
Client
  ↓
Route53
  ↓
Application Load Balancer (HTTPS)
  ↓
AWS WAF
  ↓
Kubernetes Services
  ↓
LiteLLM Pods
```

### DNS & TLS

- Dedicated Route 53 hosted zone
- Wildcard ACM certificate
- TLS termination at the ALB
- Modern TLS security policies enforced

### Gateway API

Ingress is managed through Kubernetes Gateway API resources:

- Gateway
- HTTPRoute
- GatewayClass

This provides a Kubernetes-native approach to ALB management.

### Routing

Separate routes are maintained for:

- Public API traffic
- Administrative traffic

Administrative traffic is isolated onto its own hostname.

### WAF Protection

AWS WAF protects all ingress traffic.

Controls include:

- Platform allowlists
- Administrative allowlists
- AWS managed protection rules
- Explicit blocking of non-public operational endpoints

### Backend Services

Aurora PostgreSQL and ElastiCache are deployed within private network boundaries and are only accessible from authorised workloads.

---

## Karpenter Scheduling

LiteLLM workloads are scheduled onto dedicated Karpenter-managed node pools.

### Benefits

- Automatic infrastructure scaling
- Automatic node consolidation
- Efficient utilisation of AWS Graviton processors
- Reduced operational overhead compared with fixed node groups

---

## Microsoft Entra ID SSO

The AI Gateway integrates with Microsoft Entra ID for administrator authentication.

### Benefits

- Centralised identity management
- Existing organisational access controls
- Reduced credential management overhead
- Consistent administrative experience

---

## Secrets Management

Secrets are managed using:

- AWS Secrets Manager
- External Secrets Operator

This approach provides:

- Centralised secret storage
- Automated Kubernetes secret synchronisation
- Reduced manual secret handling
- Consistent secret lifecycle management

---

## Operational Tooling

### Troubleshooting Script

`scripts/troubleshoot.sh` provides a diagnostic report for the AI Gateway deployment.

The script validates:

- Database connectivity
- ElastiCache connectivity
- Secret synchronisation
- Application health

Checks are executed from within the cluster to verify end-to-end functionality.

### Chat Completions Test Script

`chat-completions-test.sh` provides a simple method of testing AI Gateway endpoints using an API key.

This is intended as a lightweight operational validation tool for administrators.

---

# Cluster Component Changes

The AI Gateway requires several platform-level capabilities from the Data Platform cluster.

## Gateway API Upgrade

The cluster includes an upgraded Gateway API installation to support AWS Gateway API integrations and associated resources.

This enables:

- Advanced ALB configuration
- Target group configuration
- Modern Gateway API capabilities
- Compatibility with current AWS Gateway API controllers

Without this support, Gateway resources cannot be reconciled successfully.

---

## ALB Gateway API Support

The AWS Load Balancer Controller is configured to support Gateway API managed ALBs.

This allows Kubernetes Gateway resources to provision and manage Application Load Balancers directly.

Without this capability:

- Gateway resources are ignored
- No ALB infrastructure is created

---

## aws-alb GatewayClass

The cluster provides an `aws-alb` GatewayClass.

The AI Gateway references this GatewayClass to provision and manage its ingress infrastructure.

Without it:

- Gateway resources cannot bind to a controller
- ALB provisioning fails

---

## External DNS Integration

External DNS is configured to watch Gateway API routing resources.

This enables automatic Route 53 record creation for AI Gateway hostnames.

Without this capability:

- DNS records must be managed manually
- Hostnames will not resolve automatically

---

## External Secrets Integration

External Secrets permissions are extended to allow synchronisation of AI Gateway secrets from AWS Secrets Manager into Kubernetes.

This supports:

- Database credentials
- Cache credentials
- Application secrets

Without these permissions:

- Secret synchronisation fails
- Workloads cannot retrieve required configuration

---

## ListenerSet CRD Support

The cluster includes support for Gateway API ListenerSet resources.

Although the AI Gateway does not directly create ListenerSets, the CRD must exist to maintain compatibility with the Gateway API ecosystem and associated AWS integrations.

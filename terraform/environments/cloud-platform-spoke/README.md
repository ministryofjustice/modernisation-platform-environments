# Cloud Platform Spoke — CP Team

This is the Cloud Platform team's own spoke cluster, following the same
patterns that all BU spoke clusters will use. It serves as a dogfooding
environment for validating the spoke deployment process.

## Architecture

Uses EKS Auto Mode for compute management. Auto Mode handles:
- Node provisioning and scaling (no managed node groups or Karpenter)
- CNI management (no separate VPC-CNI or Cilium install)
- CoreDNS, kube-proxy, EBS CSI driver

## Component Deployment Order

```
root → network → cluster → cluster-components
```

| Component | Purpose |
|-----------|---------|
| root | Account-level baseline (Route53, OIDC, alerts) |
| network | VPC and subnets (managed centrally, placeholder for now) |
| cluster | EKS Auto Mode cluster with access entries |
| cluster-components | Gatekeeper, AWS LBC (Gateway API), WAF |

## Environments

| Workspace | Environment |
|-----------|-------------|
| cloud-platform-spoke-development | Development |
| cloud-platform-spoke-preproduction | Pre-production |
| cloud-platform-spoke-nonlive | Non-live workloads |
| cloud-platform-spoke-live | Production |

## Relationship to Hub

The hub cluster (`cloud-platform/`) runs Argo CD and manages GitOps
deployments to this spoke and future BU spokes. The Argo CD hub role
ARN in `cluster/environment-configuration.tf` grants the hub cluster
admin access to this spoke.

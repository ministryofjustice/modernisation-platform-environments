# Argo CD module

Enables the **EKS Capability for Argo CD** on a hub cluster (ADR-002). This is
the control-plane half of the Container Platform 3.0 GitOps hub and spoke model.

The Argo CD control plane runs in AWS-managed infrastructure attached to the
cluster, not as pods on worker nodes. Requires the AWS provider `>= 6.46.0`
(for the `aws_eks_capability` resource).

For the end-to-end architecture, runbooks, and troubleshooting, see the
[GitOps with ArgoCD](https://runbooks.cloud-platform.service.justice.gov.uk/cp30/gitops-argocd.html)
runbook.

## What this module creates

| Resource | Purpose |
|----------|---------|
| `aws_iam_role.argocd_capability` | Identity the managed Argo CD runs as. Named `<cluster-name>-argocd-capability`. Trusts the `capabilities.eks.amazonaws.com` service principal. This is the role a spoke registers in its EKS access entry. |
| `aws_iam_role_policy.argocd_codeconnection` | Allows the capability role to read Git through AWS CodeConnections (only when `codeconnection_arn` is set). |
| `aws_eks_capability.argocd` | The managed Argo CD capability (`type = ARGOCD`), authenticated via IAM Identity Center. One capability per cluster (an EKS hard limit). |
| `null_resource.argocd_destroy_cleanup` | Pre-destroy cleanup for routinely-destroyed clusters (only when `enable_destroy_cleanup = true`). |

## Hub vs spoke

This module configures ArgoCD on the **hub** only. It does not register spokes.

- A cluster becomes a hub by calling this module (driven by `local.enable_argocd`
  in `cluster/argocd.tf`, set from `local.argocd_hubs` or `TF_VAR_enable_argocd`).
- A **spoke** grants this module's `capability_role_arn` an EKS access entry with
  scoped RBAC. That wiring lives in `cluster/argocd.tf`, not here.

Because the managed Argo CD reaches spokes as the capability role via EKS access
entries, cross-account access is native: no VPC peering or Transit Gateway is
needed for GitOps traffic.

## Usage

```hcl
module "argocd" {
  source = "./modules/argo-cd"
  count  = local.enable_argocd ? 1 : 0

  cluster_name = module.eks.cluster_name

  idc_instance_arn   = local.argocd_idc_instance_arn
  idc_region         = local.argocd_idc_region
  rbac_role_mappings = local.argocd_rbac_role_mappings

  codeconnection_arn     = data.aws_codestarconnections_connection.github[0].arn
  enable_destroy_cleanup = local.cluster_environment == "development_cluster"

  tags = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | Name of the hub EKS cluster where the Argo CD capability is enabled. | `string` | — | yes |
| `idc_instance_arn` | ARN of the AWS IAM Identity Center instance used for Argo CD authentication. | `string` | — | yes |
| `idc_region` | Region of the IAM Identity Center instance. Defaults to the provider region. | `string` | `""` | no |
| `rbac_role_mappings` | Map of Argo CD RBAC roles (`ADMIN`, `EDITOR`, `VIEWER`) to Identity Center identities (`{ id, type }`, where `type` is `SSO_GROUP` or `SSO_USER`). | `map(list(object({ id = string, type = string })))` | `{}` | no |
| `codeconnection_arn` | AWS CodeConnections ARN for GitHub access. Empty skips the CodeConnections policy. | `string` | `""` | no |
| `enable_destroy_cleanup` | Run pre-destroy cleanup of Argo CD resources. `true` for dev clusters that are routinely destroyed; `false` for permanent hubs. | `bool` | `true` | no |
| `tags` | Additional tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `capability_arn` | ARN of the Argo CD EKS capability. |
| `capability_role_arn` | ARN of the capability's IAM role. Spokes register this role directly as their EKS access entry. |

## Notes

- **RBAC roles** map to Argo CD access levels: `ADMIN` for Cloud Platform
  engineers, `VIEWER` for application (tenant) engineers who inspect their
  Applications read-only. Keys are case-sensitive and validated.
- **`enable_destroy_cleanup`** exists because the capability's
  `delete_propagation_policy` is `RETAIN` (the only value AWS currently supports). On dev
  clusters the cleanup deletes Applications and ApplicationSets, deletes the
  capability, and clears the `argocd` namespace so the cluster teardown does not
  hang. Leave it `false` on permanent hubs.
- **CodeConnections** permissions must sit on the capability role (this module),
  because the managed Argo CD repo server authenticates to Git as that role.

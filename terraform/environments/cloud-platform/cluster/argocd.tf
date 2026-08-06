###############################################################################
# Argo CD — Hub and Spoke Configuration (ADR-002)
#
# This file handles two concerns:
#   1. Hub enablement — provisioning the EKS-managed ArgoCD Capability
#   2. Spoke registration — granting the hub access to deploy to this cluster
#
# HOW ENABLEMENT WORKS (decision tree):
#
#   Is this cluster a hub?
#     YES (workspace is in local.argocd_hubs OR TF_VAR_enable_argocd=true)
#       → Create ArgoCD Capability, CodeConnection IAM policy, hub tag
#       → Never register as a spoke
#
#     NO → Is this workspace in argocd_registered_spokes (environment config)?
#       YES → Register with the hub (create EKS Access Entry for hub role)
#       NO  → Do nothing (cluster is neither hub nor spoke)
#
# WHERE TO MAKE CHANGES:
#   - To add/remove a hub: edit argocd_hubs in locals.tf
#   - To register a spoke: add its workspace name to argocd_registered_spokes
#     in environment-configuration.tf (under the nonlive or live block)
#   - For ephemeral test hubs: pass TF_VAR_enable_argocd=true at deploy time
#   - For ephemeral test spokes: pass TF_VAR_argocd_hub_spoke_access_role_arn
#
# References:
#   - ADR-002: GitOps Fleet Management — EKS Capability for Argo CD
#   - ADR-018: Deployment Model Flexibility
###############################################################################

#------------------------------------------------------------------------------
# Hub: ArgoCD Capability
#------------------------------------------------------------------------------

# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
data "aws_codestarconnections_connection" "github" {
  count = local.enable_argocd ? 1 : 0
  name  = "github-ministryofjustice"
}

module "argocd" {
  source = "./modules/argo-cd"
  count  = local.enable_argocd ? 1 : 0

  cluster_name = module.eks.cluster_name
  cluster_arn  = module.eks.cluster_arn

  idc_instance_arn = var.argocd_idc_instance_arn
  idc_region       = var.argocd_idc_region
  rbac_role_mappings = merge(
    var.argocd_admin_group_id != "" ? {
      ADMIN = [{ id = var.argocd_admin_group_id, type = "SSO_GROUP" }]
    } : {},
    var.argocd_rbac_role_mappings
  )

  codeconnection_arn     = data.aws_codestarconnections_connection.github[0].arn
  enable_destroy_cleanup = local.cluster_environment == "development_cluster"

  tags = local.tags

  depends_on = [module.eks]
}

#------------------------------------------------------------------------------
# Spoke: Register with the hub's ArgoCD
#
# A spoke grants the hub's spoke-access role an EKS Access Entry with
# AmazonEKSClusterAdminPolicy. This allows the hub's managed ArgoCD to deploy
# workloads to this cluster without VPC peering or TGW. Cross-account access
# is native to EKS Access Entries.
#------------------------------------------------------------------------------

locals {
  # Hub's spoke-access role ARN — resolved by convention or explicit override.
  resolved_hub_spoke_access_role_arn = (
    var.argocd_hub_spoke_access_role_arn != ""
    ? var.argocd_hub_spoke_access_role_arn
    : local.argocd_hub_convention_role_arn
  )

  # A cluster never self-identifies as both hub and spoke.
  is_argocd_hub_cluster = contains(values(local.argocd_hubs)[*].cluster_name, terraform.workspace)

  # Spoke registration: workspace must appear in the argocd_registered_spokes
  # allowlist AND must not be a hub AND must be a known permanent cluster (or
  # have an explicit hub ARN for ephemeral spokes).
  is_argocd_spoke = contains(
    lookup(local.environment_configuration, "argocd_registered_spokes", []),
    terraform.workspace
    ) && !local.enable_argocd && !local.is_argocd_hub_cluster && (
    contains(local.mp_environments, terraform.workspace) || var.argocd_hub_spoke_access_role_arn != ""
  )
}

resource "aws_eks_access_entry" "argocd_spoke" {
  count = local.is_argocd_spoke ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = local.resolved_hub_spoke_access_role_arn
  type          = "STANDARD"

  tags = merge(local.tags, {
    Name    = "${module.eks.cluster_name}-argocd-spoke-access"
    Purpose = "argocd-hub-spoke-registration"
  })

  lifecycle {
    precondition {
      condition     = local.resolved_hub_spoke_access_role_arn != ""
      error_message = "Could not resolve the hub spoke-access role ARN. Ensure the spoke's tier has a hub in local.argocd_hubs, or pass TF_VAR_argocd_hub_spoke_access_role_arn."
    }
  }
}

resource "aws_eks_access_policy_association" "argocd_spoke" {
  count = local.is_argocd_spoke ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = local.resolved_hub_spoke_access_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.argocd_spoke]
}

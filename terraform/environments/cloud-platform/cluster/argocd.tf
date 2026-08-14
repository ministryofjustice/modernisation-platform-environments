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
    {
      ADMIN = [{ id = local.cloud_platform_engineers_group_id, type = "SSO_GROUP" }]
    },
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

  # Hub's ArgoCD Capability role ARN. The EKS-managed Argo CD authenticates to
  # spoke clusters as its capability role, so the spoke must grant that role
  # access — without it, API calls from the hub fail with Unauthorized and
  # Applications sit in Unknown sync state.
  #
  # Both hub roles follow the module naming "<hub-cluster>-argocd-<suffix>"
  # (see modules/argo-cd), so the capability ARN is derived from the resolved
  # spoke-access ARN. This holds for convention-based permanent hubs and for
  # explicit ephemeral-hub overrides, since both roles live in the hub account.
  resolved_hub_capability_role_arn = replace(
    local.resolved_hub_spoke_access_role_arn,
    "-argocd-spoke-access",
    "-argocd-capability"
  )

  # Access entries expose the principal to Kubernetes RBAC as a group named
  # "eks-access-entry:<principal-arn>". Binding custom RBAC to this group is
  # how we avoid attaching AmazonEKSClusterAdminPolicy (= system:masters).
  argocd_hub_capability_rbac_group = "eks-access-entry:${local.resolved_hub_capability_role_arn}"

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

#------------------------------------------------------------------------------
# Spoke: Register the hub's ArgoCD Capability role (least privilege)
#
# The EKS-managed Argo CD reaches spoke clusters as the hub's capability role,
# so that role needs its own access entry here. Deliberately NO access policy
# association: AmazonEKSClusterAdminPolicy is equivalent to system:masters and
# AWS documents it as unsuitable for production. Authorisation instead comes
# from the scoped ClusterRoles below, bound to the access entry's group.
#
# Scope rationale — Argo CD needs cluster-wide READ for discovery, health and
# drift detection, plus WRITE limited to the resource kinds our Applications
# actually manage (see cluster-core/argocd-gitops.tf AppProjects and the
# app-baseline chart: Namespace + RoleBinding + NetworkPolicy).
#
# Intentionally withheld from the hub: ClusterRole/ClusterRoleBinding writes,
# CustomResourceDefinitions, admission webhooks and node access. A compromised
# hub therefore cannot escalate cluster RBAC, install CRDs or tamper with
# admission control on a spoke (threat T-0011).
#------------------------------------------------------------------------------
resource "aws_eks_access_entry" "argocd_spoke_capability" {
  count = local.is_argocd_spoke ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = local.resolved_hub_capability_role_arn
  type          = "STANDARD"

  tags = merge(local.tags, {
    Name    = "${module.eks.cluster_name}-argocd-capability-access"
    Purpose = "argocd-hub-spoke-registration"
  })

  lifecycle {
    precondition {
      condition     = local.resolved_hub_capability_role_arn != ""
      error_message = "Could not resolve the hub capability role ARN. Ensure the spoke's tier has a hub in local.argocd_hubs, or pass TF_VAR_argocd_hub_spoke_access_role_arn."
    }
  }
}

# Cluster-wide read: required by Argo CD for resource discovery, health
# assessment and diffing desired vs live state.
resource "kubernetes_cluster_role_v1" "argocd_hub_read" {
  count = local.is_argocd_spoke ? 1 : 0

  metadata {
    name = "argocd-hub-read-all"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "container-platform/purpose"   = "argocd-hub-spoke-access"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

# Write access, limited to the resource kinds Argo CD Applications manage.
resource "kubernetes_cluster_role_v1" "argocd_hub_deploy" {
  count = local.is_argocd_spoke ? 1 : 0

  metadata {
    name = "argocd-hub-deploy"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "container-platform/purpose"   = "argocd-hub-spoke-access"
    }
  }

  # Namespace lifecycle — the app-baseline chart creates one namespace per
  # product environment. Note "finalize" is withheld.
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["create", "update", "patch", "delete"]
  }

  # Core workload resources.
  rule {
    api_groups = [""]
    resources = [
      "configmaps",
      "secrets",
      "services",
      "serviceaccounts",
      "persistentvolumeclaims",
    ]
    verbs = ["create", "update", "patch", "delete", "deletecollection"]
  }

  # Workload controllers.
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  # Ingress and network policy (incl. the baseline default-deny-ingress).
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  # Gateway API routes used by product workloads.
  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["httproutes", "grpcroutes"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  # Namespace-scoped RBAC only — the baseline grants team access per namespace.
  # ClusterRole/ClusterRoleBinding writes are deliberately excluded.
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings"]
    verbs      = ["create", "update", "patch", "delete", "deletecollection"]
  }

  # Kubernetes privilege-escalation prevention requires "bind" on a referenced
  # ClusterRole when the creator lacks those permissions itself. The baseline
  # RoleBindings reference the built-in view/edit/admin roles, so allow bind on
  # exactly those and nothing else.
  rule {
    api_groups     = ["rbac.authorization.k8s.io"]
    resources      = ["clusterroles"]
    resource_names = ["view", "edit", "admin"]
    verbs          = ["bind"]
  }
}

# Bind both ClusterRoles to the access entry's auto-generated group.
resource "kubernetes_cluster_role_binding_v1" "argocd_hub_read" {
  count = local.is_argocd_spoke ? 1 : 0

  metadata {
    name = "argocd-hub-read-all"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "container-platform/purpose"   = "argocd-hub-spoke-access"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_hub_read[0].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.argocd_hub_capability_rbac_group
  }

  depends_on = [aws_eks_access_entry.argocd_spoke_capability]
}

resource "kubernetes_cluster_role_binding_v1" "argocd_hub_deploy" {
  count = local.is_argocd_spoke ? 1 : 0

  metadata {
    name = "argocd-hub-deploy"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "container-platform/purpose"   = "argocd-hub-spoke-access"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_hub_deploy[0].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.argocd_hub_capability_rbac_group
  }

  depends_on = [aws_eks_access_entry.argocd_spoke_capability]
}

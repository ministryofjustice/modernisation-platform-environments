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
#       YES → Register with the hub (create EKS Access Entry for the hub's
#             Argo CD Capability role, the identity the EKS-managed Argo CD
#             actually authenticates as)
#       NO  → Do nothing (cluster is neither hub nor spoke)
#
# WHERE TO MAKE CHANGES:
#   - To add/remove a hub: edit argocd_hubs in locals.tf
#   - To register a spoke: add its workspace name to argocd_registered_spokes
#     in environment-configuration.tf (under the nonlive or live block)
#   - For ephemeral test hubs: pass TF_VAR_enable_argocd=true at deploy time
#   - For ephemeral test spokes: pass TF_VAR_argocd_hub_capability_role_arn
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

  idc_instance_arn = var.argocd_idc_instance_arn
  idc_region       = var.argocd_idc_region
  rbac_role_mappings = merge(
    {
      ADMIN = [
        { id = local.cloud_platform_engineers_group_id, type = "SSO_GROUP" },
        { id = local.container_platform_aws_group_id, type = "SSO_GROUP" },
      ]
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
# A spoke grants the hub's Argo CD Capability role an EKS Access Entry,
# authorised by the scoped Kubernetes RBAC below (no AmazonEKSClusterAdminPolicy
# access policy — see the access entry resource for the security rationale).
# This is the only principal a spoke needs to register: the EKS-managed Argo
# CD authenticates to spoke clusters as its capability role, not a separate
# cross-account role. Cross-account access is native to EKS Access Entries, so
# no VPC peering or TGW is required.
#------------------------------------------------------------------------------

locals {
  # Hub's Argo CD Capability role ARN — resolved by convention or explicit
  # override. Permanent hubs (nonlive/live) follow the module naming
  # "<hub-cluster>-argocd-capability" (see modules/argo-cd), so the ARN is
  # constructed directly for the spoke's tier via local.argocd_hubs. Ephemeral
  # hubs are NOT covered by that convention — for those, the engineer passes
  # the ARN explicitly as a workflow input, which arrives as
  # var.argocd_hub_capability_role_arn and takes precedence.
  resolved_hub_capability_role_arn = (
    var.argocd_hub_capability_role_arn != ""
    ? var.argocd_hub_capability_role_arn
    : local.argocd_hub_capability_convention_role_arn
  )

  # Kubernetes RBAC group that the hub capability role is placed into on this spoke.
  # The access entry declares this group explicitly via kubernetes_groups (EKS
  # does NOT auto-create an "eks-access-entry:<arn>" group), and the custom
  # ClusterRoles below bind to it. This is how we grant scoped access without
  # attaching AmazonEKSClusterAdminPolicy.
  #
  # Must be a valid Kubernetes group name (<= 63 chars), so it is a short fixed
  # label rather than anything derived from the role ARN.
  argocd_hub_capability_rbac_group = "argocd-hub"

  # A cluster never self-identifies as both hub and spoke.
  is_argocd_hub_cluster = contains(values(local.argocd_hubs)[*].cluster_name, terraform.workspace)

  # Spoke registration: workspace must appear in the argocd_registered_spokes
  # allowlist AND must not be a hub AND must be a known permanent cluster (or
  # have an explicit hub ARN for ephemeral spokes).
  is_argocd_spoke = contains(
    lookup(local.environment_configuration, "argocd_registered_spokes", []),
    terraform.workspace
    ) && !local.enable_argocd && !local.is_argocd_hub_cluster && (
    contains(local.mp_environments, terraform.workspace) || var.argocd_hub_capability_role_arn != ""
  )
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

  # Place the capability role into the RBAC group the ClusterRoleBindings below
  # bind to. Without this the principal is mapped to a username only, in no
  # group, and the scoped RBAC never applies (every API call is forbidden).
  kubernetes_groups = [local.argocd_hub_capability_rbac_group]

  tags = merge(local.tags, {
    Name    = "${module.eks.cluster_name}-argocd-capability-access"
    Purpose = "argocd-hub-spoke-registration"
  })

  lifecycle {
    precondition {
      condition     = local.resolved_hub_capability_role_arn != ""
      error_message = "Could not resolve the hub capability role ARN. Ensure the spoke's tier has a hub in local.argocd_hubs, or pass TF_VAR_argocd_hub_capability_role_arn."
    }
  }
}

# Cluster-wide read: required by Argo CD for resource discovery, health
# assessment and diffing desired vs live state.
resource "kubernetes_cluster_role_v1" "argocd_hub_read" {
  # checkov:skip=CKV_K8S_49:Cluster-wide read (get/list/watch) on all kinds is required by Argo CD for resource discovery, health and drift detection, including CRDs added later. This matches AWS's documented argocd-read-all ClusterRole for the managed Argo CD capability. Write access is scoped to specific kinds in argocd_hub_deploy; this role grants no write verbs.
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
    resources  = ["httproutes", "grpcroutes", "listenersets"]
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

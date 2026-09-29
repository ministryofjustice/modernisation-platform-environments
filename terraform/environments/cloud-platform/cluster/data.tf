data "aws_vpc" "selected" {

  filter {
    name   = "tag:Name"
    values = [local.cp_vpc_name]
  }
}

data "aws_subnets" "private" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnets" "public" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    SubnetType = "Public"
  }
}

data "aws_iam_roles" "platform_engineer_admin_sso_role" {
  name_regex  = "AWSReservedSSO_platform-engineer-admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

# ArgoCD RBAC group IDs and the assembled argocd_rbac_role_mappings are defined
# in locals.tf alongside the other ArgoCD configuration.
#
# BU parent group IDs for the VIEWER mappings are resolved from group NAMES via
# the plural aws_identitystore_groups (ListGroups) data source below. The
# ListGroups path works under the ModernisationPlatformSSOReadOnly role, unlike
# the singular data.aws_identitystore_group (GetGroupId), which returns
# ResourceNotFoundException for this role. This mirrors the working pattern in
# the root component's grafana-objects.tf (cloud-platform#8509).
#
# Only fetched on hub clusters (where ArgoCD — and therefore the RBAC mapping —
# is enabled); spokes create no ArgoCD RBAC and do not need the lookup.
data "aws_ssoadmin_instances" "this" {
  count    = local.enable_argocd ? 1 : 0
  provider = aws.sso-readonly
}

data "aws_identitystore_groups" "all" {
  count    = local.enable_argocd ? 1 : 0
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}

# Auth token for the kubernetes/helm providers (providers.tf).
# aws_eks_cluster_auth generates a token from the cluster name and the caller's
# credentials; it does NOT call the EKS API to look the cluster up, so it is
# safe on a brand-new cluster that does not exist yet.
#
# NOTE: the cluster endpoint and CA are read from module.eks outputs in
# providers.tf, NOT from a data.aws_eks_cluster lookup. A data source performs
# an eager API read at plan and fails on a first-time deploy ("reading EKS
# Cluster: couldn't find resource") because the cluster does not exist yet.
# Module outputs are known from state for existing clusters (so the providers
# reach the API at plan — preserving the #8462 plan-time refresh fix) and are
# known-after-apply on create.
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

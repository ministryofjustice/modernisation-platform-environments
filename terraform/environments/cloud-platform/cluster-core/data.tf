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

# CodeConnection for the GitHub org, used by the ArgoCD GitOps control plane to
# clone the environments monorepo through the CodeConnections git-http proxy.
# The ARN is exposed as local.argocd_codeconnection_arn (locals.tf).
#
# TODO: rename to data.aws_codeconnections_connection when the AWS provider adds
# the data source equivalent (currently only the resource exists under that name).
#
# Only looked up on hub clusters (argocd-role=hub tag). BU spoke accounts
# (container-platform-* workspaces) do not have a CodeConnection and would
# fail at plan time without this guard.
data "aws_codestarconnections_connection" "github" {
  count = lookup(data.aws_eks_cluster.cluster.tags, "argocd-role", "") == "hub" ? 1 : 0
  name  = "github-ministryofjustice"
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

# BU parent group IDs for the per-BU AppProject read-only `roles` grant (layer 2
# of the BU-user ArgoCD access model — ADR-002, cloud-platform#8548).
#
# Resolved from group NAMES via the plural aws_identitystore_groups (ListGroups)
# data source. ListGroups works under ModernisationPlatformSSOReadOnly, unlike
# the singular GetGroupId path, which returns ResourceNotFoundException for this
# role — same working pattern as the root component's grafana-objects.tf
# (cloud-platform#8509) and the cluster component's layer-1 VIEWER mapping.
#
# Hub-only: AppProjects (and therefore their roles) are created only on hub
# clusters, so spokes never need this lookup.
data "aws_ssoadmin_instances" "this" {
  count    = local.is_argocd_hub ? 1 : 0
  provider = aws.sso-readonly
}

data "aws_identitystore_groups" "all" {
  count    = local.is_argocd_hub ? 1 : 0
  provider = aws.sso-readonly

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}

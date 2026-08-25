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

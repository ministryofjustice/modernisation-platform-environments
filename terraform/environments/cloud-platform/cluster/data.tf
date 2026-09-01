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

# ArgoCD RBAC group IDs (cloud_platform_engineers_group_id,
# container_platform_aws_group_id) and the assembled argocd_rbac_role_mappings
# are defined in locals.tf alongside the other ArgoCD configuration.

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

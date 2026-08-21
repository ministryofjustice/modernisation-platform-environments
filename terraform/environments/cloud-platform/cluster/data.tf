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

# data "aws_route53_zone" "shared_parent_zone" {
#   name         = trimprefix(terraform.workspace, "cloud-platform-") + ".temp.cloud-platform.service.justice.gov.uk"
#   private_zone = false
# }

#------------------------------------------------------------------------------
# IAM Identity Center — group IDs for ArgoCD RBAC
#
# Hardcoded because the ModernisationPlatformSSOReadOnly role returns
# ResourceNotFoundException when calling GetGroupId despite having the
# identitystore:Get* permission. TODO: investigate and switch back to
# data.aws_identitystore_group lookup.
#
# - cloud-platform-engineers: the platform team, granted ArgoCD admin.
# - container-platform-aws: the AWS ProServe team working on the project,
#   granted ArgoCD admin so they can access the ArgoCD portal on hub clusters.
#------------------------------------------------------------------------------
locals {
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"
  container_platform_aws_group_id   = "7682a204-00f1-7031-257e-713bb28289c6"
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

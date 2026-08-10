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
# IAM Identity Center — cloud-platform-engineers group ID for ArgoCD RBAC
#
# Hardcoded because the ModernisationPlatformSSOReadOnly role returns
# ResourceNotFoundException when calling GetGroupId despite having the
# identitystore:Get* permission. TODO: investigate and switch back to
# data.aws_identitystore_group lookup.
#------------------------------------------------------------------------------
locals {
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

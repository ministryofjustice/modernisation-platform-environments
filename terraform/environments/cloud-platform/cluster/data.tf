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

# NOTE: do NOT add `depends_on = [module.eks]` to these EKS data sources. The
# `name` reference already creates an implicit dependency on the cluster, so
# they read only after it exists. An explicit depends_on additionally forces
# Terraform to DEFER the read whenever module.eks shows any planned change,
# making endpoint/token unknown at plan time. The kubernetes/helm providers
# (providers.tf) then fall back to localhost, breaking plan-time refresh of the
# kubernetes_* resources in this component (e.g. the ArgoCD spoke RBAC).
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

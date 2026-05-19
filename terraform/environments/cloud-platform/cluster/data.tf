data "aws_vpc" "selected" {

  filter {
    name   = "tag:Name"
    values = [local.cp_vpc_name]
  }
}

data "aws_subnets" "eks_private" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    SubnetType = "EKS-Private"
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

data "aws_eks_cluster" "cluster" {
  count      = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  name       = local.cluster_name
  depends_on = [module.eks]
}

data "external" "eks_token" {
  count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  program = ["bash", "-c", "aws eks get-token --cluster-name ${local.cluster_name} --output json | jq '{token: .status.token}'"]
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  count      = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  name       = module.eks[0].cluster_name
  depends_on = [module.eks]
}

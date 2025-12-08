data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}"]
  }
}

data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-private-*"]
  }
}

data "aws_subnets" "eks_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-public-*"]
  }
}

module "eks" {
  count = contains(local.enabled_workspaces, terraform.workspace) ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.environment
  kubernetes_version = "1.34"
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.eks_private.ids
  enable_irsa        = true


  cloudwatch_log_group_retention_in_days = 30

  eks_managed_node_groups = local.eks_managed_node_groups

  addons = {
    coredns = {
      enabled = true
      version = "v1.12.4-eksbuild.1"
    }
    kube-proxy = {
      enabled = true
      version = "v1.34.1-eksbuild.2"
    }
    vpc-cni = {
      enabled = true
      version = "v1.20.4-eksbuild.1"
    }
  }

  tags = local.tags
}
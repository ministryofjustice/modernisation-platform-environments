module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${local.name}-${local.environment}"
  kubernetes_version = local.application_data.accounts[local.environment].eks_version

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = data.aws_subnets.shared-private.ids

  enable_cluster_creator_admin_permissions = true

  endpoint_public_access                 = false
  cloudwatch_log_group_retention_in_days = 7
  # eks auto mode uses bottlerocket os
  # scaling of nodes is automated and managed by Karpenter
  # if no app is running and node is empty its scaled down
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = {
    name = "${local.name}-${local.environment}"
  }
}

# module "karpenter" {
#   count   = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
#   source  = "terraform-aws-modules/eks/aws//modules/karpenter"
#   version = "~> 21.0"

#   cluster_name = module.eks[0].cluster_name

#   create_node_iam_role = false
#   node_iam_role_arn    = module.eks[0].eks_managed_node_groups["default_ng"].iam_role_arn

#   # Since the node group role will already have an access entry
#   create_access_entry = false

#   tags = local.tags
# }

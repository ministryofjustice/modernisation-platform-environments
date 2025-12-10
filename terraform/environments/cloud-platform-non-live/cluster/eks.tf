module "eks" {
  count = contains(local.enabled_workspaces, terraform.workspace) ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.environment
  kubernetes_version = "1.34"
  vpc_id             = data.aws_vpc.selected[0].id
  subnet_ids         = data.aws_subnets.eks_private[0].ids
  enable_irsa        = true

  endpoint_private_access = true
  endpoint_public_access  = true


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

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    sso-platform-engineer-admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role[0].names)}"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    
  }

  //temporary timeouts for EKS creation
  timeouts = {
    create = "15m"
  }

  tags = local.tags
}
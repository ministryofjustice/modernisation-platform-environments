module "eks" {
  count = contains(local.enabled_workspaces, local.environment) ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.environment
  kubernetes_version = "1.34"
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.eks_private.ids
  enable_irsa        = true

  endpoint_private_access = true
  endpoint_public_access  = true

  enable_cluster_creator_admin_permissions = true

  cloudwatch_log_group_retention_in_days = 30

  eks_managed_node_groups = {
    default_ng = {
      ami_type               = local.environment_configuration.ami_type
      desired_size           = local.environment_configuration.default_ng.desired_capacity
      max_size               = local.environment_configuration.default_ng.max_size
      min_size               = local.environment_configuration.default_ng.min_size
      instance_types         = local.environment_configuration.default_ng.instance_types
      block_device_mappings  = local.environment_configuration.default_ng.block_device_mappings
      subnet_ids             = data.aws_subnets.eks_private.ids
      name                   = "${local.environment}-def-ng"
      create_security_group  = true
      create_launch_template = true
      labels                 = local.environment_configuration.default_ng.labels
    }
    monitoring_ng = {
      ami_type               = local.environment_configuration.ami_type
      desired_size           = local.environment_configuration.monitoring_ng.desired_capacity
      max_size               = local.environment_configuration.monitoring_ng.max_size
      min_size               = local.environment_configuration.monitoring_ng.min_size
      instance_types         = local.environment_configuration.monitoring_ng.instance_types
      block_device_mappings  = local.environment_configuration.monitoring_ng.block_device_mappings
      subnet_ids             = data.aws_subnets.eks_private.ids
      name                   = "${local.environment}-mon-ng"
      create_security_group  = true
      create_launch_template = true
      taints                 = local.environment_configuration.monitoring_ng.taints
      labels                 = local.environment_configuration.monitoring_ng.labels
    }
  }

  addons = {
    coredns = {
    #   version = local.environment_configuration.eks_cluster_addon_versions.coredns
    }
    kube-proxy = {
    #   version = local.environment_configuration.eks_cluster_addon_versions.kube_proxy
    }
    vpc-cni = {
    #   version = local.environment_configuration.eks_cluster_addon_versions.vpc_cni
    }
    eks-pod-identity-agent = {
    #   version = local.environment_configuration.eks_cluster_addon_versions.eks_pod_identity_agent
    }
  }

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    sso-platform-engineer-admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"
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
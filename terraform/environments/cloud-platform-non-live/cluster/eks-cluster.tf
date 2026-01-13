module "eks" {
  count = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = "1.34"
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.eks_private.ids
  enable_irsa        = true

  endpoint_private_access = true
  endpoint_public_access  = true

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
      name                   = "${local.cluster_name}-def-ng"
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
      name                   = "${local.cluster_name}-mon-ng"
      create_security_group  = true
      create_launch_template = true
      taints                 = local.environment_configuration.monitoring_ng.taints
      labels                 = local.environment_configuration.monitoring_ng.labels
    }
    karpenter = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["m5.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }

  addons = {
    coredns = {
      #   addon_version = local.environment_configuration.eks_cluster_addon_versions.coredns
    }
    kube-proxy = {
      #   addon_version = local.environment_configuration.eks_cluster_addon_versions.kube_proxy
    }
    vpc-cni = {
      before_compute = true
      #   addon_version = local.environment_configuration.eks_cluster_addon_versions.vpc_cni
    }
    eks-pod-identity-agent = {
      before_compute = true
      #   addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_pod_identity_agent
    }
    aws-guardduty-agent = {
    }

    aws-ebs-csi-driver = {
    }

  }

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    ## Cloud Platform Platform Engineer access to cluster
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
    ## MP Environments Actions (MemberInfrastructureAccess)access to cluster
    mpe-administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    ## CP GitHub actions access to cluster
    cpgha-administrator = {
      principal_arn = "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-development"]}:role/github-actions-development-cluster"
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

  tags = merge(
    local.tags,
    {
      "cluster-createdby" = var.created_by
    }
  )
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks[0].cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = local.cluster_name
  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

module "karpenter_disabled" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  create = false
}

data "aws_ecrpublic_authorization_token" "token" {
  region = "eu-west-2"
}

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.6.0"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    webhook:
      enabled: false
    EOT
  ]
}
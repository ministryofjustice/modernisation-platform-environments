#tfsec:ignore:avd-aws-0040 - EKS clusters are accessed from GitHub Actions and MoJ Digital Macs, we will evaluate if we can lock down to GitHub Actions IPv4 and MoJ Digital GlobalProtect.
#tfsec:ignore:avd-aws-0041 - Same as avd-aws-0040
#tfsec:ignore:avd-aws-0104 - Currently no requirement to lock down egress traffic from EKS cluster
module "eks" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0"

  cluster_name    = local.eks_cluster_name
  cluster_version = local.environment_configuration.eks_cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.intra_subnets
  subnet_ids               = module.vpc.private_subnets

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  iam_role_use_name_prefix = false

  cloudwatch_log_group_kms_key_id        = module.eks_cluster_logs_kms.key_arn
  cloudwatch_log_group_retention_in_days = local.eks_cloudwatch_log_group_retention_in_days
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  kms_key_aliases = ["eks/${local.eks_cluster_name}"]

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_addons = {
    /* Core Networking */
    coredns = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.coredns
    }
    kube-proxy = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.kube_proxy
    }
    /* AWS */
    aws-guardduty-agent = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_pod_identity_agent
    }
    vpc-cni = {
      addon_version            = local.environment_configuration.eks_cluster_addon_versions.vpc_cni
      service_account_role_arn = module.vpc_cni_iam_role.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_release_version = local.environment_configuration.eks_node_version
    ami_type            = "BOTTLEROCKET_x86_64"
    platform            = "bottlerocket"
    metadata_options = {
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 1
      http_tokens                 = "required"
      instance_metadata_tags      = "enabled"
    }

    block_device_mappings = {
      xvdb = {
        device_name = "/dev/xvdb"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = true
          kms_key_id            = module.ebs_kms.key_arn
          delete_on_termination = true
        }
      }
    }

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 5
      desired_size   = 3
      instance_types = ["t3.xlarge"]
    }
  }

  access_entries = {
    sso-administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.eks_sso_access_role.names)}"
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

  tags = local.tags
}

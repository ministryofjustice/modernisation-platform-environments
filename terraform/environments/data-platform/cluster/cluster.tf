module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=42693d40bceb3ad80d49b0574cc3046455c2def6" # v21.15.1

  name               = local.eks_cluster_name
  kubernetes_version = "1.35" # local.environment_configuration.eks_cluster_version

  endpoint_private_access = true
  endpoint_public_access  = true

  vpc_id                   = data.aws_vpc.main.id
  control_plane_subnet_ids = data.aws_subnets.private.ids
  subnet_ids               = data.aws_subnets.private.ids

  security_group_additional_rules = {
    vpc = {
      description = "Allow traffic from the VPC"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
    }
    cilium_vxlan = {
      description = "Cilium VXLAN overlay network"
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      type        = "ingress"
      self        = true
    }
    cilium_health = {
      description = "Cilium health checks"
      from_port   = 4240
      to_port     = 4240
      protocol    = "tcp"
      type        = "ingress"
      self        = true
    }
    cilium_hubble = {
      description = "Cilium Hubble observability"
      from_port   = 4244
      to_port     = 4244
      protocol    = "tcp"
      type        = "ingress"
      self        = true
    }
  }

  authentication_mode = "API"

  create_cloudwatch_log_group = false
  enabled_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config = {
    resources = ["secrets"]
  }

  addons = {
    /* Core Networking */
    # coredns = {
    #   addon_version = local.environment_configuration.eks_cluster_addon_versions.coredns
    # }
    # kube-proxy = {
    #   addon_version = local.environment_configuration.eks_cluster_addon_versions.kube_proxy
    # }
    # /* AWS */
    # aws-ebs-csi-driver = {
    #   addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_ebs_csi_driver
    #   service_account_role_arn = module.ebs_csi_driver_iam_role.arn
    # }
    # aws-efs-csi-driver = {
    #   addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_efs_csi_driver
    #   service_account_role_arn = module.efs_csi_driver_iam_role.arn
    # }
    # aws-guardduty-agent = {
    #   addon_version = local.environment_configuration.eks_cluster_addon_versions.aws_guardduty_agent
    # }
    # aws-network-flow-monitoring-agent = {
    #   addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_network_flow_monitoring_agent
    #   service_account_role_arn = module.aws_cloudwatch_network_flow_monitor_iam_role.arn
    # }
    # eks-pod-identity-agent = {
    #   addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_pod_identity_agent
    # }
    # eks-node-monitoring-agent = {
    #   addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_node_monitoring_agent
    # }
    # vpc-cni = {
    #   addon_version            = local.environment_configuration.eks_cluster_addon_versions.vpc_cni
    #   service_account_role_arn = module.vpc_cni_iam_role.arn
    #   configuration_values = jsonencode({
    #     env = {
    #       ENABLE_BANDWIDTH_PLUGIN = "true"
    #     }
    #   })
    # }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_cluster_name
  }

  #   eks_managed_node_groups = {
  #     system = {
  #       min_size       = 1
  #       max_size       = 10
  #       desired_size   = 3
  #       instance_types = ["m7a.large"]

  #       use_latest_ami_release_version = false
  #       ami_release_version            = "1.54.0-5043decc" # local.environment_configuration.eks_node_version
  #       ami_type                       = "BOTTLEROCKET_x86_64"
  #       platform                       = "bottlerocket"
  #       enable_monitoring              = true
  #       metadata_options = {
  #         http_endpoint               = "enabled"
  #         http_put_response_hop_limit = 1
  #         http_tokens                 = "required"
  #         instance_metadata_tags      = "enabled"
  #       }

  #       block_device_mappings = {
  #         xvdb = {
  #           device_name = "/dev/xvdb"
  #           ebs = {
  #             volume_size           = 100
  #             volume_type           = "gp3"
  #             iops                  = 3000
  #             throughput            = 150
  #             encrypted             = true
  #             kms_key_id            = module.eks_ebs_kms_key.key_arn
  #             delete_on_termination = true
  #           }
  #         }
  #       }

  #       iam_role_additional_policies = {
  #         AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  #         AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #         CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  #         # ECRPullThroughCachePolicy          = module.ecr_pull_through_cache_iam_policy.arn
  #         # EKSClusterLogsKMSAccessPolicy      = module.eks_cluster_logs_kms_access_iam_policy.arn
  #       }

  #       node_repair_config = {
  #         enabled = true
  #       }
  #     }
  #   }

  access_entries = {
    MemberInfrastructureAccess = {
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
    PlatformEngineerAAdmin = {
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
}

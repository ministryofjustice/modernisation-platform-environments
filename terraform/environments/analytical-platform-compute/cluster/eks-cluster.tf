#tfsec:ignore:avd-aws-0040 - EKS clusters are accessed from GitHub Actions and MoJ Digital Macs, we will evaluate if we can lock down to GitHub Actions IPv4 and MoJ Digital GlobalProtect.
#tfsec:ignore:avd-aws-0041 - Same as avd-aws-0040
#tfsec:ignore:avd-aws-0104 - Currently no requirement to lock down egress traffic from EKS cluster
module "eks" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks/aws"
  version = "21.9.0"

  name               = local.eks_cluster_name
  kubernetes_version = local.environment_configuration.eks_cluster_version

  endpoint_private_access = true
  endpoint_public_access  = true

  vpc_id                   = data.aws_vpc.apc.id
  control_plane_subnet_ids = data.aws_subnets.apc_intra.ids
  subnet_ids               = data.aws_subnets.apc_private.ids
  security_group_additional_rules = {
    vpc = {
      description = "Allow traffic from the VPC"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.apc.cidr_block]
    }
  }

  authentication_mode = "API"

  iam_role_use_name_prefix = false

  cloudwatch_log_group_kms_key_id        = module.eks_cluster_logs_kms.key_arn
  cloudwatch_log_group_retention_in_days = local.eks_cloudwatch_log_group_retention_in_days
  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  kms_key_aliases        = ["eks/${local.eks_cluster_name}"]
  kms_key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"]

  encryption_config = {
    resources = ["secrets"]
  }

  addons = {
    /* Core Networking */
    coredns = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.coredns
    }
    kube-proxy = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.kube_proxy
    }
    /* AWS */
    aws-ebs-csi-driver = {
      addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_ebs_csi_driver
      service_account_role_arn = module.ebs_csi_driver_iam_role.iam_role_arn
    }
    aws-efs-csi-driver = {
      addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_efs_csi_driver
      service_account_role_arn = module.efs_csi_driver_iam_role.iam_role_arn
    }
    aws-guardduty-agent = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.aws_guardduty_agent
    }
    aws-network-flow-monitoring-agent = {
      addon_version            = local.environment_configuration.eks_cluster_addon_versions.aws_network_flow_monitoring_agent
      service_account_role_arn = module.aws_cloudwatch_network_flow_monitor_iam_role.iam_role_arn
    }
    eks-pod-identity-agent = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_pod_identity_agent
    }
    eks-node-monitoring-agent = {
      addon_version = local.environment_configuration.eks_cluster_addon_versions.eks_node_monitoring_agent
    }
    vpc-cni = {
      addon_version            = local.environment_configuration.eks_cluster_addon_versions.vpc_cni
      service_account_role_arn = module.vpc_cni_iam_role.iam_role_arn
      configuration_values = jsonencode({
        env = {
          ENABLE_BANDWIDTH_PLUGIN = "true"
        }
      })
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_cluster_name
  }

  eks_managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 10
      desired_size   = 3
      instance_types = ["m6a.xlarge"]

      use_latest_ami_release_version = false
      ami_release_version            = local.environment_configuration.eks_node_version
      ami_type                       = "BOTTLEROCKET_x86_64"
      platform                       = "bottlerocket"
      enable_monitoring              = true
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
            kms_key_id            = module.eks_ebs_kms.key_arn
            delete_on_termination = true
          }
        }
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        ECRPullThroughCachePolicy          = module.ecr_pull_through_cache_iam_policy.arn
        EKSClusterLogsKMSAccessPolicy      = module.eks_cluster_logs_kms_access_iam_policy.arn
      }

      node_repair_config = {
        enabled = true
      }
    }
    airflow-high-memory = {
      min_size       = 0
      max_size       = 1
      desired_size   = 0
      instance_types = ["r7i.8xlarge"]
      labels = {
        high-memory = "true"
      }
      taints = {
        high_memory = {
          key    = "high-memory"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      use_latest_ami_release_version = false
      ami_release_version            = local.environment_configuration.eks_node_version
      ami_type                       = "BOTTLEROCKET_x86_64"
      platform                       = "bottlerocket"
      enable_monitoring              = true
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
            volume_size           = 200
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 250
            encrypted             = true
            kms_key_id            = module.eks_ebs_kms.key_arn
            delete_on_termination = true
          }
        }
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        ECRPullThroughCachePolicy          = module.ecr_pull_through_cache_iam_policy.arn
        EKSClusterLogsKMSAccessPolicy      = module.eks_cluster_logs_kms_access_iam_policy.arn
      }

      node_repair_config = {
        enabled = true
      }
    }
  }

  access_entries = {
    # Modernisation Platform Environments (MemberInfrastructureAccess)access to cluster
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
    # Analytical Platform Engineering access to cluster
    sso-administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.eks_sso_access_role.names)}"
      policy_associations = {
        eks-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
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
    # MWAA access to MWAA role in MWAA namespace
    apc-mwaa = {
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/mwaa-execution"
      username          = "apc-mwaa"
      kubernetes_groups = ["mwaa"]
    }
    # Analytical Platform Common access to MWAA ServiceAccount management role in MWAA namespace
    gha-mojap-common = {
      principal_arn     = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/analytical-platform-github-actions"
      username          = "github-actions-moj-ap-airflow"
      kubernetes_groups = ["mwaa-serviceaccount-management", "mwaa-external-secrets"]
    }
    /* Legacy Airflow */
    data-engineering-airflow = {
      principal_arn     = local.environment_configuration.data_engineering_airflow_execution_role_arn
      username          = "data-engineering-airflow"
      kubernetes_groups = ["airflow"]
    }
    github-actions-mojas-airflow = {
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-mojas-airflow"
      username          = "github-actions-mojas-airflow"
      kubernetes_groups = ["airflow-serviceaccount-management"]
    }
  }

  tags = local.tags
}

#tfsec:ignore:avd-aws-0104 NACLs not restricted
module "karpenter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.9.0"

  cluster_name = module.eks.cluster_name

  create_pod_identity_association = true

  namespace = kubernetes_namespace.karpenter.metadata[0].name

  queue_name                = "${module.eks.cluster_name}-karpenter"
  queue_kms_master_key_id   = module.karpenter_sqs_kms.key_arn
  queue_managed_sse_enabled = false

  iam_policy_name = "karpenter"
  iam_role_name   = "karpenter"
  iam_role_policies = {
    KarpenterSQSKMSAccess = module.karpenter_sqs_kms_access_iam_policy.arn
  }

  node_iam_role_name = "karpenter"
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EKSClusterLogsKMSAccessPolicy = module.eks_cluster_logs_kms_access_iam_policy.arn
  }

  tags = local.tags
}

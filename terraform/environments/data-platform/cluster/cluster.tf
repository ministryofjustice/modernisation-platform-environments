module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=42693d40bceb3ad80d49b0574cc3046455c2def6" # v21.15.1

  name               = local.eks_cluster_name
  kubernetes_version = local.cluster_configuration.kubernetes_version

  endpoint_private_access = true
  endpoint_public_access  = true

  vpc_id                   = data.aws_vpc.main.id
  control_plane_subnet_ids = data.aws_subnets.private.ids
  subnet_ids               = data.aws_subnets.private.ids

  create_node_security_group = false

  authentication_mode = "API"

  create_cloudwatch_log_group = false
  enabled_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  kms_key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"]

  encryption_config = {
    resources = ["secrets"]
  }

  addons = {}

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
    PlatformEngineerAdmin = {
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

module "eks_managed_node_group_system" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/eks-managed-node-group?ref=42693d40bceb3ad80d49b0574cc3046455c2def6" # v21.15.1

  name         = "system"
  cluster_name = module.eks.cluster_name

  subnet_ids = data.aws_subnets.private.ids

  # Security groups required for nodes to join cluster
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.node_security_group.security_group_id]

  # Service CIDR required for Bottlerocket user data (EKS default)
  cluster_service_cidr = "172.20.0.0/16"

  # Instance configuration
  min_size       = 3
  max_size       = 10
  desired_size   = 3
  instance_types = ["m8g.large"]

  # Bottlerocket configuration
  ami_type                       = "BOTTLEROCKET_ARM_64"
  use_latest_ami_release_version = false
  ami_release_version            = local.cluster_configuration.bottlerocket_version

  enable_monitoring = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  labels = {
    "compute.data-platform.service.justice.gov.uk/node" = "system"
  }

  taints = {
    node-group = {
      key    = "compute.data-platform.service.justice.gov.uk/node"
      value  = "system"
      effect = "NO_SCHEDULE"
    }
    cilium = {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  }


  # EBS volume configuration
  block_device_mappings = {
    xvdb = {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        encrypted             = true
        kms_key_id            = module.eks_ebs_kms_key.key_arn
        delete_on_termination = true
      }
    }
  }

  # IAM policies for node functionality
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Enable automatic node repair
  node_repair_config = {
    enabled = true
  }
}

module "eks_managed_node_group_general" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/eks-managed-node-group?ref=42693d40bceb3ad80d49b0574cc3046455c2def6" # v21.15.1

  name         = "general"
  cluster_name = module.eks.cluster_name

  subnet_ids = data.aws_subnets.private.ids

  # Security groups required for nodes to join cluster
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.node_security_group.security_group_id]

  # Service CIDR required for Bottlerocket user data (EKS default)
  cluster_service_cidr = "172.20.0.0/16"

  # Instance configuration
  min_size       = 3
  max_size       = 10
  desired_size   = 3
  instance_types = ["m8g.large"]

  # Bottlerocket configuration
  ami_type                       = "BOTTLEROCKET_ARM_64"
  use_latest_ami_release_version = false
  ami_release_version            = local.cluster_configuration.bottlerocket_version

  enable_monitoring = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  labels = {
    "compute.data-platform.service.justice.gov.uk/node" = "general"
  }

  taints = {
    # node-group = {
    #   key    = "compute.data-platform.service.justice.gov.uk/node"
    #   value  = "general"
    #   effect = "NO_SCHEDULE"
    # }
    cilium = {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  }


  # EBS volume configuration
  block_device_mappings = {
    xvdb = {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        encrypted             = true
        kms_key_id            = module.eks_ebs_kms_key.key_arn
        delete_on_termination = true
      }
    }
  }

  # IAM policies for node functionality
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Enable automatic node repair
  node_repair_config = {
    enabled = true
  }
}

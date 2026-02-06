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

  kms_key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"]

  encryption_config = {
    resources = ["secrets"]
  }

  addons = {
    # coredns = {
    #   addon_version               = "v1.13.2-eksbuild.1" # local.environment_configuration.eks_cluster_addon_versions.coredns
    #   preserve                    = true
    #   resolve_conflicts_on_create = "OVERWRITE"
    #   resolve_conflicts_on_update = "PRESERVE"
    #   configuration_values = jsonencode({
    #     tolerations = [
    #       {
    #         key      = "CriticalAddonsOnly"
    #         operator = "Exists"
    #       },
    #       {
    #         key    = "node-role.kubernetes.io/control-plane"
    #         effect = "NoSchedule"
    #       },
    #       {
    #         key      = "node.cilium.io/agent-not-ready"
    #         operator = "Exists"
    #         effect   = "NoSchedule"
    #       }
    #     ]
    #   })
    # }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.eks_cluster_name
  }

  # Node groups moved to separate module with dependency on Cilium
  # See eks-node-groups.tf

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

# module "eks_system_node_group" {
#   source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

#   name         = "system"
#   cluster_name = module.eks.cluster_name

#   subnet_ids = data.aws_subnets.private.ids

#   // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
#   // Without it, the security groups of the nodes are empty and thus won't join the cluster.
#   cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
#   vpc_security_group_ids            = [module.eks.node_security_group_id]

#   cluster_service_cidr = data.aws_eks_cluster.eks.kubernetes_network_config[0].service_ipv4_cidr

#   // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
#   // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
#   // use_custom_launch_template = false
#   // disk_size = 50
#   //
#   //  # Remote access cannot be specified with a launch template
#   //  remote_access = {
#   //    ec2_ssh_key               = module.key_pair.key_pair_name
#   //    source_security_group_ids = [aws_security_group.remote_access.id]
#   //  }

#   min_size     = 1
#   max_size     = 10
#   desired_size = 1

#   instance_types = ["t3.large"]


# }

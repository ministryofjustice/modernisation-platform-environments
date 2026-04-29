module "eks" {
  count = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = local.environment_configuration.eks_cluster_version
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
    default_ng_arm = {
      ami_type               = local.environment_configuration.ami_type_arm
      desired_size           = local.environment_configuration.default_ng_arm.desired_capacity
      max_size               = local.environment_configuration.default_ng_arm.max_size
      min_size               = local.environment_configuration.default_ng_arm.min_size
      instance_types         = local.environment_configuration.default_ng_arm.instance_types
      block_device_mappings  = local.environment_configuration.default_ng_arm.block_device_mappings
      subnet_ids             = data.aws_subnets.eks_private.ids
      name                   = "${local.cluster_name}-def-ng"
      create_security_group  = true
      create_launch_template = true
      labels                 = local.environment_configuration.default_ng_arm.labels
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
    system_ng = {
      ami_type               = local.environment_configuration.ami_type
      desired_size           = local.environment_configuration.system_ng.desired_capacity
      max_size               = local.environment_configuration.system_ng.max_size
      min_size               = local.environment_configuration.system_ng.min_size
      instance_types         = local.environment_configuration.system_ng.instance_types
      block_device_mappings  = local.environment_configuration.system_ng.block_device_mappings
      subnet_ids             = data.aws_subnets.eks_private.ids
      name                   = "${local.cluster_name}-sys-ng"
      create_security_group  = true
      create_launch_template = true
      taints                 = local.environment_configuration.system_ng.taints
      labels                 = local.environment_configuration.system_ng.labels
    }
    # karpenter = {
    #   ami_type       = "BOTTLEROCKET_x86_64"
    #   instance_types = ["m5.large"]

    #   min_size     = 2
    #   max_size     = 3
    #   desired_size = 2

    #   labels = {
    #     # Used to ensure Karpenter runs on nodes that it does not manage
    #     "karpenter.sh/controller" = "true"
    #   }
    # }
  }

  addons = {
    coredns = {
      #   addon_version = local.environment_configuration.eks_cluster_addon_versions.coredns
      configuration_values = jsonencode({
        nodeSelector = {
          "cloud-platform.justice.gov.uk/system-ng" = "true"
        }
        tolerations = [
          {
            key      = "system-node"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          }
        ]
      })
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
      configuration_values = jsonencode({
        controller = {
          nodeSelector = {
            "cloud-platform.justice.gov.uk/system-ng" = "true"
          }
          tolerations = [
            {
              key      = "system-node"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            }
          ]
        }
      })
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
      principal_arn = "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-development"]}:role/github-actions-development-cluster"
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

module "karpenter" {
  count  = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
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
}


resource "helm_release" "karpenter" {
  count      = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.9.0"
  wait       = false

  values = [
    <<-EOT
   nodeSelector:
     cloud-platform.justice.gov.uk/system-ng: 'true'
   tolerations:
     - key: system-node
       operator: Equal
       value: "true"
       effect: NoSchedule
   dnsPolicy: Default
   settings:
     clusterName: ${module.eks[0].cluster_name}
     clusterEndpoint: ${module.eks[0].cluster_endpoint}
     interruptionQueue: ${module.karpenter[0].queue_name}
   webhook:
     enabled: false
   EOT
  ]
  depends_on = [
    module.karpenter[0]
  ]
}


data "kubectl_path_documents" "manifests" {
  pattern = "${path.module}/templates/karpenter.yaml"
  vars = {
    alias_version = "v20260304"
    cluster_name  = try(module.eks[0].cluster_name, "")
  }
}

resource "kubectl_manifest" "deploy_manifest" {
  for_each  = contains(local.enabled_workspaces, local.cluster_environment) ? data.kubectl_path_documents.manifests.manifests : {}
  yaml_body = each.value

  depends_on = [
    helm_release.karpenter[0]
  ]
}
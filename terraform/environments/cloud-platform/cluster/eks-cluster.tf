module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.22"

  name               = local.cluster_name
  kubernetes_version = local.environment_configuration.eks_cluster_version
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.private.ids
  enable_irsa        = true

  endpoint_private_access = true
  endpoint_public_access  = true
  # endpoint_public_access_cidrs = ["0.0.0.0/0"]

  iam_role_name            = "${trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")}-cluster"
  iam_role_use_name_prefix = false

  node_iam_role_name            = "${trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")}-eks-auto"
  node_iam_role_use_name_prefix = false

  # enable_cluster_creator_admin_permissions = true ## CP GitHub actions access to cluster, Adds to access entries
  compute_config = {
    enabled    = true
    node_pools = ["system"] # US-028: general-purpose removed — user workloads use custom-networking NodePool only
  }
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cloudwatch_log_group_retention_in_days = 30
  addons = {
    aws-guardduty-agent = {
    },
    coredns = {
    },
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
    ## MP Environments Actions (github-actions-plan) access to cluster
    github-actions-plan = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan"
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

  tags = merge(
    local.tags,
    null_resource.created_by_tag.triggers.created_by == "__unset__" ? {} : { "created-by" = null_resource.created_by_tag.triggers.created_by }
  )
}

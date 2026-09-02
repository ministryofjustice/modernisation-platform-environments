module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.22"

  name               = local.cluster_name
  kubernetes_version = local.environment_configuration.eks_cluster_version
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.private.ids
  enable_irsa        = true

  endpoint_private_access = true
  ## Public access is off when the VPC is tagged private-endpoint-mode=true. The
  ## network component sets that tag and deploys the SSM relay from the same
  ## value, so the endpoint and the relay cannot disagree.
  endpoint_public_access = !local.private_endpoint_mode
  # endpoint_public_access_cidrs = ["0.0.0.0/0"]

  iam_role_name            = "${trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")}-cluster"
  iam_role_use_name_prefix = false

  node_iam_role_name            = "${trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")}-eks-auto"
  node_iam_role_use_name_prefix = false

  # enable_cluster_creator_admin_permissions = true ## CP GitHub actions access to cluster, Adds to access entries
  compute_config = {
    enabled    = true
    node_pools = ["system"]
  }
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cloudwatch_log_group_retention_in_days = 30
  addons = {
    aws-guardduty-agent = {
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
    null_resource.created_by_tag.triggers.created_by == "__unset__" ? {} : { "created-by" = null_resource.created_by_tag.triggers.created_by },
    local.enable_argocd ? { "argocd-role" = "hub" } : {}
  )
}

## EKS Auto Mode component logs via CloudWatch Vended Logs
locals {
  auto_mode_log_types = {
    AUTO_MODE_COMPUTE_LOGS        = "compute"        # Karpenter
    AUTO_MODE_BLOCK_STORAGE_LOGS  = "block-storage"  # EBS CSI
    AUTO_MODE_LOAD_BALANCING_LOGS = "load-balancing" # AWS Load Balancer Controller
    AUTO_MODE_IPAM_LOGS           = "ipam"           # VPC CNI IP address management
  }

  auto_mode_source_names = {
    AUTO_MODE_COMPUTE_LOGS        = aws_cloudwatch_log_delivery_source.auto_mode_compute.name
    AUTO_MODE_BLOCK_STORAGE_LOGS  = aws_cloudwatch_log_delivery_source.auto_mode_block_storage.name
    AUTO_MODE_LOAD_BALANCING_LOGS = aws_cloudwatch_log_delivery_source.auto_mode_load_balancing.name
    AUTO_MODE_IPAM_LOGS           = aws_cloudwatch_log_delivery_source.auto_mode_ipam.name
  }
}

## Delivery destinations. The naming alone does not grant write access — see the
## resource policy below.
resource "aws_cloudwatch_log_group" "auto_mode" {
  for_each = local.auto_mode_log_types

  name              = "/aws/vendedlogs/eks/cluster/${each.key}/${local.cluster_name}"
  retention_in_days = 30

  tags = merge(local.tags, { Name = "/aws/vendedlogs/eks/cluster/${each.key}/${local.cluster_name}" })
}

## Allows the delivery service to write to the vendedlogs log groups.
data "aws_iam_policy_document" "auto_mode_vendedlogs" {
  statement {
    sid    = "AWSLogDeliveryWriteVendedLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vendedlogs/*:log-stream:*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "auto_mode_vendedlogs" {
  policy_name     = "auto-mode-vendedlogs-delivery"
  policy_document = data.aws_iam_policy_document.auto_mode_vendedlogs.json
}

## Created one at a time with waits: each triggers an async EKS cluster update and
## the API allows only one, so parallel creation hits ConflictException.
resource "aws_cloudwatch_log_delivery_source" "auto_mode_compute" {
  name         = "${local.cluster_name}-compute"
  log_type     = "AUTO_MODE_COMPUTE_LOGS"
  resource_arn = module.eks.cluster_arn

  tags = local.tags
}

resource "time_sleep" "auto_mode_after_compute" {
  depends_on      = [aws_cloudwatch_log_delivery_source.auto_mode_compute]
  create_duration = "120s"
}

resource "aws_cloudwatch_log_delivery_source" "auto_mode_block_storage" {
  name         = "${local.cluster_name}-block-storage"
  log_type     = "AUTO_MODE_BLOCK_STORAGE_LOGS"
  resource_arn = module.eks.cluster_arn

  tags = local.tags

  depends_on = [time_sleep.auto_mode_after_compute]
}

resource "time_sleep" "auto_mode_after_block_storage" {
  depends_on      = [aws_cloudwatch_log_delivery_source.auto_mode_block_storage]
  create_duration = "120s"
}

resource "aws_cloudwatch_log_delivery_source" "auto_mode_load_balancing" {
  name         = "${local.cluster_name}-load-balancing"
  log_type     = "AUTO_MODE_LOAD_BALANCING_LOGS"
  resource_arn = module.eks.cluster_arn

  tags = local.tags

  depends_on = [time_sleep.auto_mode_after_block_storage]
}

resource "time_sleep" "auto_mode_after_load_balancing" {
  depends_on      = [aws_cloudwatch_log_delivery_source.auto_mode_load_balancing]
  create_duration = "120s"
}

resource "aws_cloudwatch_log_delivery_source" "auto_mode_ipam" {
  name         = "${local.cluster_name}-ipam"
  log_type     = "AUTO_MODE_IPAM_LOGS"
  resource_arn = module.eks.cluster_arn

  tags = local.tags

  depends_on = [time_sleep.auto_mode_after_load_balancing]
}

resource "aws_cloudwatch_log_delivery_destination" "auto_mode" {
  for_each = local.auto_mode_log_types

  name = "${local.cluster_name}-${each.value}"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.auto_mode[each.key].arn
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_delivery" "auto_mode" {
  for_each = local.auto_mode_log_types

  delivery_source_name     = local.auto_mode_source_names[each.key]
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.auto_mode[each.key].arn

  tags = local.tags

  # CreateDelivery needs the destination log-group resource policy in place first.
  depends_on = [aws_cloudwatch_log_resource_policy.auto_mode_vendedlogs]
}

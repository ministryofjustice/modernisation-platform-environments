locals {
  enabled_workspaces = ["cloud-platform-non-live-development"]

  # desired_capacity change is a manual step after initial cluster creation (when no cluster-autoscaler)
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/835
  node_groups_count = {
    cloud-platform-non-live-development  = "1"
    cloud-platform-non-live-test         = "1"
    cloud-platform-non-live-preproduction = "1"
    cloud-platform-non-live-production   = "1"
  }

  # Default node group minimum capacity
  default_ng_min_count = {
    cloud-platform-non-live-development  = "1"
    cloud-platform-non-live-test         = "1"
    cloud-platform-non-live-preproduction = "1"
    cloud-platform-non-live-production   = "1"
  }

  # Monitoring node group desired capacity
  default_mon_desired_count = {
    cloud-platform-non-live-development  = "1"
    cloud-platform-non-live-test         = "1"
    cloud-platform-non-live-preproduction = "1"
    cloud-platform-non-live-production   = "1"
  }

  # Monitoring node group minimum capacity
  default_mon_min_count = {
    cloud-platform-non-live-development  = "1"
    cloud-platform-non-live-test         = "1"
    cloud-platform-non-live-preproduction = "1"
    cloud-platform-non-live-production   = "1"
  }

  node_size = {
    cloud-platform-non-live-development  = ["r6i.large", "r6i.xlarge", "r5.large"]
    cloud-platform-non-live-test         = ["r6i.large", "r6i.xlarge", "r5.large"]
    cloud-platform-non-live-preproduction = ["r6i.large", "r6i.xlarge", "r5.large"]
    cloud-platform-non-live-production   = ["r6i.large", "r6i.xlarge", "r5.large"]
  }

  monitoring_node_size = {
    cloud-platform-non-live-development  = ["r7i.large", "r6i.12xlarge", "r7i.16xlarge", "r6i.16xlarge"]
    cloud-platform-non-live-test         = ["r7i.large", "r6i.12xlarge", "r7i.16xlarge", "r6i.16xlarge"]
    cloud-platform-non-live-preproduction = ["r7i.large", "r6i.12xlarge", "r7i.16xlarge", "r6i.16xlarge"]
    cloud-platform-non-live-production   = ["r7i.large", "r6i.12xlarge", "r7i.16xlarge", "r6i.16xlarge"]

  }

  default_ng = {
    desired_size = lookup(local.node_groups_count, terraform.workspace)
    max_size     = 120
    min_size     = lookup(local.default_ng_min_count, terraform.workspace)

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 200
          volume_type           = "gp3"
          iops                  = 0
          encrypted             = false
          kms_key_id            = ""
          delete_on_termination = true
        }
      }
    }

    subnet_ids = try(data.aws_subnets.eks_private[0].ids, [])
    name       = "${local.environment}-def-ng"

    create_security_group  = false
    create_launch_template = true

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # ami_type = "AL2023_x86_64_STANDARD"
    ami_type       = "BOTTLEROCKET_x86_64"
    instance_types = lookup(local.node_size, terraform.workspace)
    labels = {
      Terraform                                  = "true"
      "cloud-platform.justice.gov.uk/default-ng" = "true"
      Cluster                                    = terraform.workspace
    }
  }

  monitoring_ng = {
    desired_size = lookup(local.default_mon_desired_count, terraform.workspace)
    max_size     = 6
    min_size     = lookup(local.default_mon_min_count, terraform.workspace)
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 140
          volume_type           = "gp3"
          iops                  = 0
          encrypted             = false
          kms_key_id            = ""
          delete_on_termination = true
        }
      }
    }

    subnet_ids = try(data.aws_subnets.eks_private[0].ids, [])
    name       = "${local.environment}-mon-ng"

    create_security_group  = false
    create_launch_template = true

    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # ami_type = "AL2023_x86_64_STANDARD"
    ami_type       = "BOTTLEROCKET_x86_64"
    instance_types = lookup(local.monitoring_node_size, terraform.workspace)
    labels = {
      Terraform                                     = "true"
      "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
      Cluster                                       = terraform.workspace
    }
    taints = {
      monitoring = {
        key    = "monitoring-node"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }

  eks_managed_node_groups = {
    default_ng    = local.default_ng
    monitoring_ng = local.monitoring_ng
  }
}
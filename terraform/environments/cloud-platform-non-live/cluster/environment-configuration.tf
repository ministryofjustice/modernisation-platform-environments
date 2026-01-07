locals {
  environment_configurations = {
    development_cluster = {
      /* EKS */
      eks_cluster_version = "1.34"

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.20.1-eksbuild.1"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.3.8-eksbuild.2"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r6i.large"]

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

        labels = {
          Terraform                                  = "true"
          "cloud-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                    = local.environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r6i.large"]

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

        taints = {
          monitoring = {
            key    = "monitoring-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                       = local.environment
        }
      }
    }
    development = {
      /* EKS */
      eks_cluster_version = "1.34"

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.20.1-eksbuild.1"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.3.8-eksbuild.2"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r6i.large"]

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

        labels = {
          Terraform                                  = "true"
          "cloud-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                    = local.environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r6i.large"]

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

        taints = {
          monitoring = {
            key    = "monitoring-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                       = local.environment
        }
      }
    }
    test = {
      /* EKS */
      eks_cluster_version = "1.34"

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.20.1-eksbuild.1"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.13.6-eksbuild.1"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r6i.large"]

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

        labels = {
          Terraform                                  = "true"
          "cloud-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                    = local.environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r6i.large"]

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

        taints = {
          monitoring = {
            key    = "monitoring-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                       = local.environment
        }
      }
    }
    preproduction = {
      /* EKS */
      eks_cluster_version = "1.34"

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.20.1-eksbuild.1"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.3.8-eksbuild.2"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r6i.large"]

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

        labels = {
          Terraform                                  = "true"
          "cloud-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                    = local.environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r6i.large"]

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

        taints = {
          monitoring = {
            key    = "monitoring-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                       = local.environment
        }
      }
    }
    production = {
      /* EKS */
      eks_cluster_version = "1.34"

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.20.1-eksbuild.1"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.3.8-eksbuild.2"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r6i.large"]

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

        labels = {
          Terraform                                  = "true"
          "cloud-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                    = local.environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r6i.large"]

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

        taints = {
          monitoring = {
            key    = "monitoring-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                       = local.environment
        }
      }
    }
  }
}

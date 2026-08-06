locals {
  environment_configurations = {
    development_cluster = {
      /* EKS */
      # private_endpoint_mode: single source of truth for private cluster access.
      # true = private-only API + SSM relay deployed (via network); false = public endpoint, no relay.
      eks_cluster_version   = "1.35"
      private_endpoint_mode = true

      /* Addons */
      eks_cluster_addon_versions = {
        kube_proxy             = "v1.34.2-eksbuild.1"
        vpc_cni                = "v1.21.2-eksbuild.2"
        coredns                = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent = "v1.3.8-eksbuild.2"
      }

      /* Nodes */
      ami_type = "AL2023_x86_64_STANDARD"

      default_ng = {
        min_size         = 2
        desired_capacity = 3
        max_size         = 10

        instance_types = ["r8i.large"]

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
          Terraform                                      = "true"
          "cloud-platform.justice.gov.uk/default-ng"     = "true"
          "container-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                        = local.cluster_environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r8i.large"]

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
          Terraform                                         = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng"     = "true"
          "container-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                           = local.cluster_environment
        }
      }
      system_ng = {
        min_size         = 2
        desired_capacity = 2
        max_size         = 4

        instance_types = ["r8i.large"]

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
            key    = "system-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/system-ng"     = "true"
          "container-platform.justice.gov.uk/system-ng" = "true"
          Cluster                                       = local.cluster_environment
        }
      }
    }
    development = {
      /* EKS */
      # private_endpoint_mode: see development_cluster above.
      eks_cluster_version   = "1.35"
      private_endpoint_mode = true

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

        instance_types = ["r8i.large"]

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
          Terraform                                      = "true"
          "cloud-platform.justice.gov.uk/default-ng"     = "true"
          "container-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                        = local.cluster_environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r8i.large"]

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
          Terraform                                         = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng"     = "true"
          "container-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                           = local.cluster_environment
        }
      }
      system_ng = {
        min_size         = 2
        desired_capacity = 2
        max_size         = 4

        instance_types = ["r8i.large"]

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
            key    = "system-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/system-ng"     = "true"
          "container-platform.justice.gov.uk/system-ng" = "true"
          Cluster                                       = local.cluster_environment
        }
      }
    }
    preproduction = {
      /* EKS */
      # private_endpoint_mode: see development_cluster above. false until opted in.
      eks_cluster_version   = "1.35"
      private_endpoint_mode = false

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

        instance_types = ["r8i.large"]

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
          Terraform                                      = "true"
          "cloud-platform.justice.gov.uk/default-ng"     = "true"
          "container-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                        = local.cluster_environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r8i.large"]

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
          Terraform                                         = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng"     = "true"
          "container-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                           = local.cluster_environment
        }
      }
      system_ng = {
        min_size         = 2
        desired_capacity = 2
        max_size         = 4

        instance_types = ["r8i.large"]

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
            key    = "system-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/system-ng"     = "true"
          "container-platform.justice.gov.uk/system-ng" = "true"
          Cluster                                       = local.cluster_environment
        }
      }
    }
    nonlive = {
      /* EKS */
      # private_endpoint_mode: see development_cluster above. false until opted in.
      eks_cluster_version   = "1.35"
      private_endpoint_mode = false

      /* ArgoCD — spokes registered with the preproduction hub */
      argocd_registered_spokes = [
        "container-platform-octo-nonlive",
      ]

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

        instance_types = ["r8i.large"]

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
          Terraform                                      = "true"
          "cloud-platform.justice.gov.uk/default-ng"     = "true"
          "container-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                        = local.cluster_environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r8i.large"]

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
          Terraform                                         = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng"     = "true"
          "container-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                           = local.cluster_environment
        }
      }
      system_ng = {
        min_size         = 2
        desired_capacity = 2
        max_size         = 4

        instance_types = ["r8i.large"]

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
            key    = "system-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/system-ng"     = "true"
          "container-platform.justice.gov.uk/system-ng" = "true"
          Cluster                                       = local.cluster_environment
        }
      }
    }
    live = {
      /* EKS */
      # private_endpoint_mode: see development_cluster above. false until opted in.
      eks_cluster_version   = "1.35"
      private_endpoint_mode = false

      /* ArgoCD — spokes registered with the live hub */
      argocd_registered_spokes = []

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

        instance_types = ["r8i.large"]

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
          Terraform                                      = "true"
          "cloud-platform.justice.gov.uk/default-ng"     = "true"
          "container-platform.justice.gov.uk/default-ng" = "true"
          Cluster                                        = local.cluster_environment
        }
      }

      monitoring_ng = {
        min_size         = 1
        desired_capacity = 2
        max_size         = 5

        instance_types = ["r8i.large"]

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
          Terraform                                         = "true"
          "cloud-platform.justice.gov.uk/monitoring-ng"     = "true"
          "container-platform.justice.gov.uk/monitoring-ng" = "true"
          Cluster                                           = local.cluster_environment
        }
      }
      system_ng = {
        min_size         = 2
        desired_capacity = 2
        max_size         = 4

        instance_types = ["r8i.large"]

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
            key    = "system-node"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }

        labels = {
          Terraform                                     = "true"
          "cloud-platform.justice.gov.uk/system-ng"     = "true"
          "container-platform.justice.gov.uk/system-ng" = "true"
          Cluster                                       = local.cluster_environment
        }
      }
    }
  }
}

locals {
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.200.0.0/18"
      vpc_public_subnets         = ["10.200.0.0/27", "10.200.0.32/27", "10.200.0.64/27"]
      vpc_database_subnets       = ["10.200.0.128/27", "10.200.0.160/27", "10.200.0.192/27"]
      vpc_elasticache_subnets    = ["10.200.1.0/27", "10.200.1.32/27", "10.200.1.64/27"]
      vpc_intra_subnets          = ["10.200.1.128/27", "10.200.1.160/27", "10.200.1.192/27"]
      vpc_private_subnets        = ["10.200.32.0/21", "10.200.40.0/21", "10.200.48.0/21"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Transit Gateway */
      transit_gateway_routes = [] # development is not connected to the Transit Gateway

      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.33"
      eks_node_version    = "1.44.0-244cd3a5"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.33.3-eksbuild.4"
        aws_efs_csi_driver                = "v2.1.10-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.0.3-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.0-eksbuild.2"
        coredns                           = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent            = "v1.3.8-eksbuild.2"
        aws_guardduty_agent               = "v1.10.0-eksbuild.2"
        aws_ebs_csi_driver                = "v1.47.0-eksbuild.1"
        vpc_cni                           = "v1.20.1-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

      /* UI */
      ui_hostname = "development.analytical-platform.service.justice.gov.uk"

      /* Network Monitoring */
      hmcts_sdp_endpoints          = {}
      hmcts_sdp_onecrown_endpoints = {}
    }
    test = {
      /* VPC */
      vpc_cidr                   = "10.200.64.0/18"
      vpc_public_subnets         = ["10.200.64.0/27", "10.200.64.32/27", "10.200.64.64/27"]
      vpc_database_subnets       = ["10.200.64.128/27", "10.200.64.160/27", "10.200.64.192/27"]
      vpc_elasticache_subnets    = ["10.200.65.0/27", "10.200.65.32/27", "10.200.65.64/27"]
      vpc_intra_subnets          = ["10.200.65.128/27", "10.200.65.160/27", "10.200.65.192/27"]
      vpc_private_subnets        = ["10.200.96.0/21", "10.200.104.0/21", "10.200.112.0/21"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Transit Gateway */
      transit_gateway_routes = [
        "10.0.0.0/8",      # Internal 10.x.x.x
        "172.20.0.0/16",   # Cloud Platform
        "194.33.254.0/24", # SOP
        "194.33.255.0/24", # SOP
      ]

      /* Route53 */
      route53_zone = "compute.test.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.33"
      eks_node_version    = "1.44.0-244cd3a5"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.33.3-eksbuild.4"
        aws_efs_csi_driver                = "v2.1.10-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.0.3-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.0-eksbuild.2"
        coredns                           = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent            = "v1.3.8-eksbuild.2"
        aws_guardduty_agent               = "v1.10.0-eksbuild.2"
        aws_ebs_csi_driver                = "v1.47.0-eksbuild.1"
        vpc_cni                           = "v1.20.1-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

      /* UI */
      ui_hostname = "test.analytical-platform.service.justice.gov.uk"

      /* Network Monitoring */
      hmcts_sdp_endpoints          = {}
      hmcts_sdp_onecrown_endpoints = {}
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.201.0.0/16"
      vpc_public_subnets         = ["10.201.0.0/26", "10.201.0.64/26", "10.201.0.128/26"]
      vpc_database_subnets       = ["10.201.1.0/26", "10.201.1.64/26", "10.201.1.128/26"]
      vpc_elasticache_subnets    = ["10.201.2.0/26", "10.201.2.64/26", "10.201.2.128/26"]
      vpc_intra_subnets          = ["10.201.3.0/26", "10.201.3.64/26", "10.201.3.128/26"]
      vpc_private_subnets        = ["10.201.128.0/19", "10.201.160.0/19", "10.201.192.0/19"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true
      vpc_single_nat_gateway     = false

      /* Transit Gateway */
      transit_gateway_routes = [
        "10.0.0.0/8",      # Internal 10.x.x.x
        "172.20.0.0/16",   # Cloud Platform
        "194.33.254.0/24", # SOP
        "194.33.255.0/24", # SOP
      ]

      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.33"
      eks_node_version    = "1.44.0-244cd3a5"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.33.3-eksbuild.4"
        aws_efs_csi_driver                = "v2.1.10-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.0.3-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.0-eksbuild.2"
        coredns                           = "v1.12.2-eksbuild.4"
        eks_pod_identity_agent            = "v1.3.8-eksbuild.2"
        aws_guardduty_agent               = "v1.10.0-eksbuild.2"
        aws_ebs_csi_driver                = "v1.47.0-eksbuild.1"
        vpc_cni                           = "v1.20.1-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-prod-execution-role"

      /* UI */
      ui_hostname = "analytical-platform.service.justice.gov.uk"

      /* LF Domain Tags */
      cadet_lf_tags = {
        domain = [
          "bold",
          "cica",
          "cjs_cross_dataset",
          "civil",
          "corporate",
          "counter_terrorism",
          "courts",
          "criminal_history",
          "data_first",
          "development_sandpit",
          "electronic_monitoring",
          "family",
          "finance",
          "general",
          "interventions",
          "laa",
          "opg",
          "people",
          "performance",
          "prison",
          "probation",
          "property",
          "public",
          "risk",
          "sentence_offence",
          "staging",
          "victims",
          "victims_case_management"
        ]
      }

      /* Network Monitoring */
      hmcts_sdp_endpoints = {
        mipersistentithc-blob = {
          destination      = "10.168.4.13"
          destination_port = 443
        }
        miexportithc-blob = {
          destination      = "10.168.4.5"
          destination_port = 443
        }
        mipersistentstg-blob = {
          destination      = "10.168.3.8"
          destination_port = 443
        }
        miexportstg-blob = {
          destination      = "10.168.3.7"
          destination_port = 443
        }
        mipersistentprod-blob = {
          destination      = "10.168.5.13"
          destination_port = 443
        }
        miexportprod-blob = {
          destination      = "10.168.5.8"
          destination_port = 443
        }
        baisbaumojapnle-blob = {
          destination      = "10.225.251.100"
          destination_port = 443
        }
        baisbaumojapprod-blob = {
          destination      = "10.224.251.100"
          destination_port = 443
        }
        miadhoclandingprod-blob = {
          destination      = "10.168.5.4"
          destination_port = 443
        }
      }

      hmcts_sdp_onecrown_endpoints = {
        mi-synapse-dev-sql = {
          destination      = "10.168.1.14"
          destination_port = 1433
        }
        mi-synapse-prod-sql = {
          destination      = "10.168.5.16"
          destination_port = 1433
        }
      }
    }
  }
}

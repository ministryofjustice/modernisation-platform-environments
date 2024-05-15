locals {
  /* VPC */
  our_vpc_name                                        = "${local.application_name}-${local.environment}"
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.our_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  /* EKS */
  eks_cluster_name                           = "${local.application_name}-${local.environment}"
  eks_cloudwatch_log_group_retention_in_days = 400


  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]
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

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.29"
      eks_node_version    = "1.19.5-64049ba8"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.1-eksbuild.9"
        kube_proxy             = "v1.29.3-eksbuild.2"
        eks_pod_identity_agent = "v1.2.0-eksbuild.1"
        vpc_cni                = "v1.18.1-eksbuild.3"
        aws_guardduty_agent    = "v1.5.0-eksbuild.1"
      }

      /* Observability Platform */
      observability_platform = "development"
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

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.29"
      eks_node_version    = "1.19.5-64049ba8"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.1-eksbuild.9"
        kube_proxy             = "v1.29.3-eksbuild.2"
        eks_pod_identity_agent = "v1.2.0-eksbuild.1"
        vpc_cni                = "v1.18.1-eksbuild.3"
        aws_guardduty_agent    = "v1.5.0-eksbuild.1"
      }

      /* Observability Platform */
      observability_platform = "development"
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

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.29"
      eks_node_version    = "1.19.5-64049ba8"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.1-eksbuild.9"
        kube_proxy             = "v1.29.3-eksbuild.2"
        eks_pod_identity_agent = "v1.2.0-eksbuild.1"
        vpc_cni                = "v1.18.1-eksbuild.3"
        aws_guardduty_agent    = "v1.5.0-eksbuild.1"
      }

      /* Observability Platform */
      observability_platform = "production"
    }
  }
}

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
      eks_node_version    = "1.41.0-bc3ad241"
      eks_cluster_addon_versions = {
        coredns                           = "v1.12.1-eksbuild.2"
        kube_proxy                        = "v1.33.0-eksbuild.2"
        aws_ebs_csi_driver                = "v1.44.0-eksbuild.1"
        aws_efs_csi_driver                = "v2.1.8-eksbuild.1"
        aws_guardduty_agent               = "v1.10.0-eksbuild.2"
        aws_network_flow_monitoring_agent = "v1.0.2-eksbuild.5"
        eks_pod_identity_agent            = "v1.3.7-eksbuild.2"
        eks_node_monitoring_agent         = "v1.3.0-eksbuild.2"
        vpc_cni                           = "v1.19.6-eksbuild.1"
      }
    }
  }
}

locals {
  environment_configurations = {
    development = {

      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.34"
      eks_node_version    = "1.51.0-47438798"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.33.5-eksbuild.2"
        aws_efs_csi_driver                = "v2.1.15-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.1.1-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.2-eksbuild.1"
        coredns                           = "v1.12.4-eksbuild.1"
        eks_pod_identity_agent            = "v1.3.10-eksbuild.1"
        aws_guardduty_agent               = "v1.12.1-eksbuild.2"
        aws_ebs_csi_driver                = "v1.53.0-eksbuild.1"
        vpc_cni                           = "v1.20.5-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

    }
    test = {

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

    }
    production = {

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

    }
  }
}

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
        kube_proxy                        = "v1.34.1-eksbuild.2"
        aws_efs_csi_driver                = "v2.1.15-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.1.1-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.2-eksbuild.1"
        coredns                           = "v1.12.4-eksbuild.1"
        eks_pod_identity_agent            = "v1.3.10-eksbuild.1"
        aws_guardduty_agent               = "v1.12.1-eksbuild.2"
        aws_ebs_csi_driver                = "v1.53.0-eksbuild.1"
        vpc_cni                           = "v1.20.5-eksbuild.1"
      }

      helm_chart_version = {
        aws_cloudwatch_metrics = "0.0.11"
        aws_for_fluent_bit     = "0.1.35"
        cert_manager           = "v1.18.1"
        cluster_autoscaler     = "9.46.6"
        external_dns           = "1.17.0"
        external_secrets       = "0.18.0"
        ingress_nginx          = "4.12.3"
        karpenter              = "1.8.2"
        keda                   = "2.17.2"
        kube_prometheus_stack  = "75.3.5"
        kyverno                = "3.4.3"
        velero                 = "10.0.10"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

    }
    test = {

      /* Route53 */
      route53_zone = "compute.test.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.34"
      eks_node_version    = "1.51.0-47438798"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.34.1-eksbuild.2"
        aws_efs_csi_driver                = "v2.1.15-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.1.1-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.2-eksbuild.1"
        coredns                           = "v1.12.4-eksbuild.1"
        eks_pod_identity_agent            = "v1.3.10-eksbuild.1"
        aws_guardduty_agent               = "v1.12.1-eksbuild.2"
        aws_ebs_csi_driver                = "v1.53.0-eksbuild.1"
        vpc_cni                           = "v1.20.5-eksbuild.1"
      }

      helm_chart_version = {
        aws_cloudwatch_metrics = "0.0.11"
        aws_for_fluent_bit     = "0.1.35"
        cert_manager           = "v1.18.1"
        cluster_autoscaler     = "9.46.6"
        external_dns           = "1.17.0"
        external_secrets       = "0.18.0"
        ingress_nginx          = "4.12.3"
        karpenter              = "1.8.2"
        keda                   = "2.17.2"
        kube_prometheus_stack  = "75.3.5"
        kyverno                = "3.4.3"
        velero                 = "10.0.10"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

    }
    production = {

      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.34"
      eks_node_version    = "1.51.0-47438798"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.34.1-eksbuild.2"
        aws_efs_csi_driver                = "v2.1.15-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.1.1-eksbuild.1"
        eks_node_monitoring_agent         = "v1.4.2-eksbuild.1"
        coredns                           = "v1.12.4-eksbuild.1"
        eks_pod_identity_agent            = "v1.3.10-eksbuild.1"
        aws_guardduty_agent               = "v1.12.1-eksbuild.2"
        aws_ebs_csi_driver                = "v1.53.0-eksbuild.1"
        vpc_cni                           = "v1.20.5-eksbuild.1"
      }

      helm_chart_version = {
        aws_cloudwatch_metrics = "0.0.11"
        aws_for_fluent_bit     = "0.1.35"
        cert_manager           = "v1.18.1"
        cluster_autoscaler     = "9.46.6"
        external_dns           = "1.17.0"
        external_secrets       = "0.18.0"
        ingress_nginx          = "4.12.3"
        karpenter              = "1.8.2"
        keda                   = "2.17.2"
        kube_prometheus_stack  = "75.3.5"
        kyverno                = "3.4.3"
        velero                 = "10.0.10"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-prod-execution-role"

    }
  }
}

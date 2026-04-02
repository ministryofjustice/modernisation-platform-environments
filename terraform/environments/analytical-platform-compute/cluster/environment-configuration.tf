locals {
  environment_configurations = {
    development = {

      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.35"
      eks_node_version    = "1.57.0-beaadc52"
      eks_cluster_addon_versions = {
        kube_proxy                        = "v1.35.2-eksbuild.4"
        aws_efs_csi_driver                = "v2.3.1-eksbuild.1"
        aws_network_flow_monitoring_agent = "v1.1.3-eksbuild.2"
        eks_node_monitoring_agent         = "v1.6.2-eksbuild.1"
        coredns                           = "v1.13.2-eksbuild.4"
        eks_pod_identity_agent            = "v1.3.10-eksbuild.2"
        aws_guardduty_agent               = "v1.12.1-eksbuild.2"
        aws_ebs_csi_driver                = "v1.57.1-eksbuild.1"
        vpc_cni                           = "v1.21.1-eksbuild.5"
      }

      helm_chart_version = {
        aws_cloudwatch_metrics = "0.0.11"
        aws_for_fluent_bit     = "0.2.0"
        cert_manager           = "v1.19.2"
        cluster_autoscaler     = "9.56.0"
        external_dns           = "1.20.0"
        external_secrets       = "2.2.0"
        ingress_nginx          = "4.15.0"
        karpenter              = "1.10.0"
        keda                   = "2.18.3"
        kube_prometheus_stack  = "82.16.0"
        kyverno                = "3.6.2"
        velero                 = "12.0.0"
      }

      /* Velero */
      velero_aws_plugin_version = "v1.14.0"

      /* Kube Prometheus Stack */
      prometheus_operator_crd_version = "v0.89.0"

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
        cert_manager           = "v1.19.2"
        cluster_autoscaler     = "9.54.1"
        external_dns           = "1.20.0"
        external_secrets       = "1.2.1"
        ingress_nginx          = "4.15.0"
        karpenter              = "1.8.5"
        keda                   = "2.18.3"
        kube_prometheus_stack  = "81.1.0"
        kyverno                = "3.6.2"
        velero                 = "11.3.2"
      }

      /* Velero */
      velero_aws_plugin_version = "v1.13.2"

      /* Kube Prometheus Stack */
      prometheus_operator_crd_version = "v0.88.0"

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
        cert_manager           = "v1.19.2"
        cluster_autoscaler     = "9.54.1"
        external_dns           = "1.20.0"
        external_secrets       = "1.2.1"
        ingress_nginx          = "4.15.0"
        karpenter              = "1.8.5"
        keda                   = "2.18.3"
        kube_prometheus_stack  = "81.1.0"
        kyverno                = "3.6.2"
        velero                 = "11.3.2"
      }

      /* Velero */
      velero_aws_plugin_version = "v1.13.2"

      /* Kube Prometheus Stack */
      prometheus_operator_crd_version = "v0.88.0"

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-prod-execution-role"

    }
  }
}

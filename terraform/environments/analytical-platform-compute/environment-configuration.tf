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
      transit_gateway_routes = [
        "10.0.0.0/8",
        "172.20.0.0/16"
      ]

      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.36.0-00ef7af1"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.41.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.7-eksbuild.1"
        aws_guardduty_agent    = "v1.9.0-eksbuild.2"
        eks_pod_identity_agent = "v1.3.5-eksbuild.2"
        vpc_cni                = "v1.19.3-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

      /* MLFlow */
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-development"

      /* UI */
      ui_hostname = "development.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.small"
      airflow_webserver_instance_name = "Development"
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
        "10.0.0.0/8",
        "172.20.0.0/16"
      ]

      /* Route53 */
      route53_zone = "compute.test.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.36.0-00ef7af1"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.41.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.7-eksbuild.1"
        aws_guardduty_agent    = "v1.9.0-eksbuild.2"
        eks_pod_identity_agent = "v1.3.5-eksbuild.2"
        vpc_cni                = "v1.19.3-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-dev-execution-role"

      /* MLFlow */
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-test"

      /* UI */
      ui_hostname = "test.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.medium"
      airflow_webserver_instance_name = "Test"
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
        "10.0.0.0/8",
        "172.20.0.0/16"
      ]

      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.36.0-00ef7af1"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.41.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.7-eksbuild.1"
        aws_guardduty_agent    = "v1.9.0-eksbuild.2"
        eks_pod_identity_agent = "v1.3.5-eksbuild.2"
        vpc_cni                = "v1.19.3-eksbuild.1"
      }

      /* Data Engineering Airflow */
      data_engineering_airflow_execution_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/airflow-prod-execution-role"

      /* MLFlow */
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow"

      /* UI */
      ui_hostname = "analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.medium"
      airflow_webserver_instance_name = "Production"

      /* LF Domain Tags */
      cadet_lf_tags = {
        domain = [
          "bold",
          "civil",
          "courts",
          "general",
          "criminal_history",
          "development_sandpit",
          "electronic_monitoring",
          "finance",
          "interventions",
          "opg",
          "performance",
          "risk",
          "people",
          "prison",
          "probation",
          "staging",
          "victims",
          "victims_case_management",
          "cica",
          "data_first",
          "laa",
          "corporate",
          "property",
          "family"
        ]
      }
    }
  }
}

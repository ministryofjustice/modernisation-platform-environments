locals {
  airflow_dag_s3_path          = "dags/"
  airflow_requirements_s3_path = "requirements.txt"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.26.128.0/21"
      vpc_private_subnets        = ["10.26.130.0/23", "10.26.132.0/23", "10.26.134.0/23"]
      vpc_public_subnets         = ["10.26.128.0/27", "10.26.128.32/27", "10.26.128.64/27"]
      vpc_database_subnets       = ["10.26.128.96/27", "10.26.128.128/27", "10.26.128.160/27"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = false

      /* EKS */
      eks_cluster_name = "apps-tools-${local.environment}"
      eks_versions = {
        cluster                   = "1.28"
        ami_release               = "1.16.0-d2d9cf87" // [major version].[minor version].[patch version]-[first 8 chars of commit SHA]. Get the SHA from here: https://github.com/bottlerocket-os/bottlerocket/releases
        addon_coredns             = "v1.10.1-eksbuild.5"
        addon_kube_proxy          = "v1.28.2-eksbuild.2"
        addon_vpc_cni             = "v1.15.3-eksbuild.1"
        addon_aws_guardduty_agent = "v1.3.1-eksbuild.1"
        addon_ebs_csi_driver      = "v1.24.1-eksbuild.1"
        addon_efs_csi_driver      = "v1.7.0-eksbuild.1"
      }
      eks_sso_access_role = "modernisation-platform-sandbox"

      /* Airflow */
      airflow_execution_role_name   = "${local.application_name}-${local.environment}-airflow-execution"
      airflow_s3_bucket             = "moj-data-platform-airflow-development20230627094128036000000001" // This is defined in modernisation-platform-environments
      airflow_dag_s3_path           = "dags/"                                                           // This is defined in modernisation-platform-environments
      airflow_requirements_s3_path  = "requirements.txt"                                                // This is defined in modernisation-platform-environments
      airflow_execution_role_name   = "${local.application_name}-${local.environment}-airflow-execution"
      airflow_name                  = "${local.application_name}-${local.environment}"
      airflow_version               = "2.6.3"
      airflow_environment_class     = "mw1.medium"
      airflow_max_workers           = 2
      airflow_min_workers           = 1
      airflow_schedulers            = 2
      airflow_webserver_access_mode = "PUBLIC_ONLY"
      airflow_configuration_options = {
        "webserver.warn_deployment_exposure" = 0
      }
      airflow_mail_from_address               = "airflow"
      airflow_weekly_maintenance_window_start = "SAT:00:00"

      ### OLDER

      eks_cluster_arn                = "arn:aws:eks:eu-west-2:335889174965:cluster/apps-tools-development"
      eks_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJV04xQi9kT3BSYTB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpBNU1Ua3hPRFU1TVRsYUZ3MHpNekE1TVRZeE9EVTVNVGxhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNkLzBaK0JLdFVTWlUvS2dJeVI0aVllMWtFemhGaXBqK1oxbzV1eTVrMGlVU3ZmNm5GWElNWkRmdVcKZWVnVDVpNUhsZ1dRNVBaYm10MkJVbE1DR3lmUWsxa0c4MzNyYXVpUElsdXl5NDh2M0pKZUxOQ2RHQm1wb1Z6LwpoZk1BNUlpejlHRVdZMkVtTFJEMlFOMjlQS3R1VDhFUUVQL3p6WW9Yd0d5QUVUd1RQOTlnMG9lKzJqb3o5ZzZyCm1ZNmFHQTkzazg0QkMvTDBWYVRYZFFMT21vVHBncnRGdnU5VTlXQlBOTmhVTlduVDlMb0NpYktveFhDQzV4eU0KUHJHNXluSHM0OEszWjVVUURXTTY2S1VRcDBVaTdzVndlNkU2TG11eGcvNGFyZ1A1SkptSFJFTkNTQkFvdlBMQwpaZCtYNDF6WGtsOTczVDRXSjI3WUpJcTBNZ1N4QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJScjk3NU1TS2Y2bzRiUk5IUjhNeXUxRUJmdmFqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQjdwYjFOakI1cgpWaWcwb1pzOFByY2thTDh2aU1DYUdVQXBRTUlQeE00bnlHREF4VEU5aXNrOWlBc1BkbWlveDNuL1JOVW8wYmpiCm8rRnYvWUxXTlJCS0xxdWpKVWVWYUoyZzVIVDlQZVQvVEdsZzhuNkgyRzFHLzFmR3UybllFdVk2S2c3bzJadGcKRG1QazJFUzAwTVkzYkgrN2VoYURoaldpbzl1N2RQVGVsdnRVaU5Kbkd0TlAwMVZMUXJhK0t6SHZpd3N2VFkrYgo5d1VsQTIzYnFNK1cxQ0hTajdSbzFFckpBVEZXamdmVnZ2UUlYRnN3TmFsemM2VW1VN3ZPSEI3cDE3MEh3WGI2ClVOd2RVek4rc2JKRElodHhwV25KOXFtVlhkVnlycTJ5Q2V1M2FKdFFDMVltcWVaZFIwOW1mSjhaS2ZMMTlpTEoKTS9rU0NvZE5ueW53Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
      eks_server                     = "https://BEE86BED6494692D4ED31C2ED2319E13.gr7.eu-west-2.eks.amazonaws.com"
      eks_cluster_name               = "apps-tools-development"
      route53_zone                   = "apps-tools.development.data-platform.service.justice.gov.uk"
      ses_domain_identity            = "apps-tools.development.data-platform.service.justice.gov.uk"
      auth0_log_streams = {
        "dev-analytics-moj" = {
          event_source_name = "aws.partner/auth0.com/dev-analytics-moj-20c1595d-28e2-4822-9e1c-cb29ac38c7d2/auth0.logs"
        }
        "ministryofjustice-data-platform-development" = {
          event_source_name = "aws.partner/auth0.com/ministryofjustice-data-platform-development-a628362c-f79b-46e9-9604-7c9861565a1b/auth0.logs"
        }
      }
      openmetadata_role = "openmetadata"
      openmetadata_target_accounts = [
        local.environment_management.account_ids["data-platform-development"],
        local.environment_management.account_ids["analytical-platform-data-production"]
      ]
      datahub_role = "openmetadata"
      datahub_target_accounts = [
        local.environment_management.account_ids["data-platform-development"],
        local.environment_management.account_ids["analytical-platform-data-production"]
      ]

      observability_platform_account_id     = local.environment_management.account_ids["observability-platform-development"]
      observability_platform_role           = "data-platform-apps-and-tools-development-prometheus"
      observability_platform_prometheus_url = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-464eea97-631a-4e5d-af22-4c5528d9e0e6/api/v1/remote_write"
      static_assets_hostname = "assets.development.data-platform.service.justice.gov.uk"
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.27.128.0/21"
      vpc_private_subnets        = ["10.27.130.0/23", "10.27.132.0/23", "10.27.134.0/23"]
      vpc_public_subnets         = ["10.27.128.0/27", "10.27.128.32/27", "10.27.128.64/27"]
      vpc_database_subnets       = ["10.27.128.96/27", "10.27.128.128/27", "10.27.128.160/27"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = false

      /* EKS */
      eks_cluster_name = "apps-tools-${local.environment}"
      eks_versions = {
        cluster                   = "1.28"
        ami_release               = "1.16.0-d2d9cf87" // [major version].[minor version].[patch version]-[first 8 chars of commit SHA]. Get the SHA from here: https://github.com/bottlerocket-os/bottlerocket/releases
        addon_coredns             = "v1.10.1-eksbuild.5"
        addon_kube_proxy          = "v1.28.2-eksbuild.2"
        addon_vpc_cni             = "v1.15.3-eksbuild.1"
        addon_aws_guardduty_agent = "v1.3.1-eksbuild.1"
        addon_ebs_csi_driver      = "v1.24.1-eksbuild.1"
        addon_efs_csi_driver      = "v1.7.0-eksbuild.1"
      }
      eks_sso_access_role = "modernisation-platform-developer"

      /* Airflow */
      airflow_s3_bucket             = "moj-data-platform-airflow-production20230908140747954800000002" // This is defined in modernisation-platform-environments
      airflow_dag_s3_path           = "dags/"                                                          // This is defined in modernisation-platform-environments
      airflow_requirements_s3_path  = "requirements.txt"                                               // This is defined in modernisation-platform-environments
      airflow_execution_role_name   = "${local.application_name}-${local.environment}-airflow-execution"
      airflow_name                  = "${local.application_name}-${local.environment}"
      airflow_version               = "2.6.3"
      airflow_environment_class     = "mw1.medium"
      airflow_max_workers           = 2
      airflow_min_workers           = 1
      airflow_schedulers            = 2
      airflow_webserver_access_mode = "PUBLIC_ONLY"
      airflow_configuration_options = {
        "webserver.warn_deployment_exposure" = 0
      }
      airflow_mail_from_address               = "airflow"
      airflow_weekly_maintenance_window_start = "SAT:00:00"

      /* Open Metadata */
      openmetadata_role = "openmetadata"
      openmetadata_target_accounts = [
        local.environment_management.account_ids["data-platform-production"],
        local.environment_management.account_ids["analytical-platform-data-production"]
      ]

      /* Observability Platform */
      observability_platform_account_id     = local.environment_management.account_ids["observability-platform-production"]
      observability_platform_role           = "data-platform-apps-and-tools-production-prometheus"
      observability_platform_prometheus_url = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-55a65e9b-aab9-47a0-88b4-8275c50f1ff9/api/v1/remote_write"

      /* Static Assets */
      static_assets_hostname = "assets.data-platform.service.justice.gov.uk"

      ### OLD
      eks_cluster_arn                = "arn:aws:eks:eu-west-1:312423030077:cluster/production-dBSvju9Y"
      eks_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1EZ3lOREV5TVRBd05Gb1hEVE14TURneU1qRXlNVEF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGtyCllrNVhVT3VyU3M0T2o3aE5XRE0zSC9vUnhUMmY0c014eGJoMEEwM010OXQ5SUtBaWM2TFpiMlZJd3VobG14bUIKaVhuSEtXSHREbi85NUwwdEgvWURnN3VFSXVMa2xMS3F0NjRVWlFFWHNocElaakxpNFU1bW03WWttT1N4VjFYSQo4bXJ4VEhaRGZ1NHZwdURUSWdmR2szTE8rTXBBZVgrTFNFM1JVSWR4UFo1eDVzYloyU29NWkFYekRnaHEzOU9RCjY3WVNFdmRYS1Bkd1JDUnR0d2k4OGVuOGpxanRZMFB5dUVaMVQzRjVPeWhBMjNQWVBMam10aWt2akNwMmNKOTkKZnhUNG1NNWsyUUlxQmxZWTRzR0s3dzhTL1I2VGxtL1g4KzBjeWhyU2FmMjh2dUNVL0dXZVJ6MWhYa05rV2FKTQpkampuWElzeFRkc0tGc1RUMzVVQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZQVkpZMGlHcW9RODlmMy9sbkNsdUQ4NnZvUDNNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBb2tScklHRzRWbVBGMnBhV3dSdEdhU01NVnBaWDdRRGhEL0tSajY5NXZLOU1YaDJnSgpPeWR3enRJd2tMalNjZUhaZTJocE9DNkt3VUxMbFJYRzJRbXhzUnJtaEM5NU8xWEM1cURZV2JFRUoxUnpsUkJGCkdQT1FMQ0tWTnc4b21KTlRXcDdTTDgxeFBiZCtnNm1KSlB3UHQ2cVJHNTBaMnRVSzZVRnZSbVRUcXl3Z1U4UXkKemp5cFJMVkJtQWc3Tkw3MW9zS0x4T25qUHRHNDl4eVNTVExQaGpDSzlIUnM5bXJDaVJ0RWo1b2EwUHY3d2hIOQpWQS8yYVVmRTA5cjg4dXFYWHIvZlNoY1FXSlhmU1gvYVVIbFZwK0NJU2tHUkJscmFKc3ZHSlZ3UWJRR3ZvTGZmCnMyTFo3M1EzbHpDM2VOajJ6WTcrbTdlazVLOUJEc29oK2lWeAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
      eks_server                     = "https://EB06461747C1D40013EE978C4D8D1755.gr7.eu-west-1.eks.amazonaws.com"
      eks_cluster_name               = "apps-tools-production"
      route53_zone                   = "apps-tools.data-platform.service.justice.gov.uk"
      ses_domain_identity            = "apps-tools.data-platform.service.justice.gov.uk"
      auth0_log_streams = {
        "alpha-analytics-moj" = {
          event_source_name = "aws.partner/auth0.com/alpha-analytics-moj-5246b1ce-4ea2-45ab-9c2d-1414d6ff608a/auth0.logs"
        }
        "ministryofjustice-data-platform" = {
          event_source_name = "aws.partner/auth0.com/ministryofjustice-data-platform-e95e4fb0-f6f8-455f-9b62-61608adafd69/auth0.logs"
        }
      }
      datahub_role = "openmetadata"
      datahub_target_accounts = [
        local.environment_management.account_ids["data-platform-production"],
        local.environment_management.account_ids["analytical-platform-data-production"]
      ]
    }
  }
}

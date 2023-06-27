locals {
  # airflow_name                            = local.environment
  # airflow_dag_s3_path                     = "dags/"
  airflow_requirements_s3_path = "requirements.txt"
  # airflow_webserver_access_mode           = "PUBLIC_ONLY"
  # airflow_weekly_maintenance_window_start = "SAT:00:00"
  # airflow_mail_from_address               = "airflow@${local.ses_domain_identity}"

  route53_zone        = "apps-tools.${local.environment}.data-platform.service.justice.gov.uk"
  ses_domain_identity = "apps-tools.${local.environment}.data-platform.service.justice.gov.uk"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      # airflow_version           = "2.4.3"
      # airflow_environment_class = "mw1.small"
      # airflow_max_workers       = 2
      # airflow_min_workers       = 1
      # airflow_schedulers        = 2
      # airflow_configuration_options = {
      #   "webserver.warn_deployment_exposure" = 0
      # }
      eks_cluster_arn                = "arn:aws:eks:eu-west-1:525294151996:cluster/development-aWrhyc0m"
      eks_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1USXdOVEE1TkRReU5sb1hEVE14TVRJd016QTVORFF5Tmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBSnlICmZ2MStZR0ZGZUpKbGJGUVVuK2N1N0hSRWRiTldHUzVSZWNCNlE3YWprNnYrT2xoZ3lZR0FzeXBiR291LzRUNXUKM2JSUjJYS1lkZk9tSmNSMzBVMUNzNExFZWJrSXVndERBenBvdW8yZHBPd3liMjJSVndwRWgvd1dUL1ZFV2ZjUQpwVEhkVEQ2RWQ4NkNGWEd0akxrTFN2UWtPQ0IzUnR4anZPOFlvSVZIaXdMWW4yenJmdytoTW9RSHhQRnh3UDRZCmJyTFkzZzJxVFArMjV4dE5TcDBua1IwQnZUMEwzazVRUTNNQUZ3RzBSWmhvRlBpNlJ2VzRPYWc2OFhFeHJVTUcKRE1YUXlEL3NsWGhtbVR2cjd3MHVtQlBSeHdZbFUxdzlkZFp0NjRDVytTeEdGUlRyNm41U1ZPWStDUjlhR2NuSgo4SDFMQ3J5RENuNnlHSDVBSHhrQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZNZFowR083STNDdFNKbDFHczRuaGt6US81WXNNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCSFNXK25OK01xeCtBT3R1aUhjQ3hEeXhvMU5VWXRtK29TaUthMm9kVEIrVTI4UFdOagpYUFMzamF4Nyt5K05MQ0psVENWcllxVHZhQit2V3pVV3lqVzBHZGN5K29TR3FWdTNvcXBuNDBVazkzWXRnRkZQCmIrRVdwbjZ4R1BodDVROGZ6ZE9adCtKbVQ5SElsYTVPSDJJejY5T2dtYjUvQU1YNW94ajlRZVFQVEh0Ym5DNDAKWlRRZHlXMTRQTXZwQmV1QnFQM3ZhZHRabHkvU1RLQnZzMk9qV3Y3WStNMXBtQWdFWHV4TTQ2Nzl6ZFpnbEdYegpFRm1mNTZlUmJLQXZyN3o3ZkpmV0dSNTRvdkpNZGJ0NFAxOWVxRm8vd05IRHNTK1ZuTVJ5azkxQUdBNmVwQWFDCjFyZVp5R3VUSnZuU0hxTzJ2VHBOdWhkWlo4RWtjSU03Vlk5KwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
      eks_server                     = "https://6F58D1C4FD8FAE6D3D9282A400EDCE79.gr7.eu-west-1.eks.amazonaws.com"
      eks_cluster_name               = "development-aWrhyc0m"
    }
  }
}

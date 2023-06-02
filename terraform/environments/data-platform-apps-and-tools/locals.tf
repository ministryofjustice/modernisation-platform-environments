locals {
  airflow_name        = local.environment
  airflow_dag_s3_path = "dags/"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      airflow_version           = "2.4.3"
      airflow_environment_class = "mw1.medium"
    }
  }
}
##################################################
# Main
##################################################

resource "aws_mwaa_environment" "main" {
  name               = "data-platform-airflow"
  airflow_version    = "2.5.1"
  environment_class  = "mw1.medium"

  execution_role_arn = module.airflow_execution_role.iam_role_arn

  source_bucket_arn = module.airflow_s3_bucket.bucket.arn
  dag_s3_path       = "dags/"

  network_configuration {
    security_group_ids = [module.airflow_security_group.security_group_id]
    subnet_ids         = [data.aws_subnets.mp_platforms_development_general_private.ids]
  }
}
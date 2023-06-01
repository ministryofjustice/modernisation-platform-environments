##################################################
# Main
##################################################

resource "aws_mwaa_environment" "main" {
  name              = local.airflow_environment_name
  airflow_version   = var.airflow_version
  environment_class = var.airflow_environment_class

  execution_role_arn = module.airflow_execution_role.iam_role_arn

  source_bucket_arn = module.airflow_s3_bucket.bucket.arn
  dag_s3_path       = var.airflow_dag_s3_path

  network_configuration {
    security_group_ids = [module.airflow_security_group.security_group_id]
    subnet_ids         = slice(data.aws_subnets.mp_platforms_development_general_private.ids, 0, 1)
  }
}

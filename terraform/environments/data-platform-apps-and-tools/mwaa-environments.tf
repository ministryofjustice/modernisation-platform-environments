##################################################
# Main
##################################################

resource "aws_mwaa_environment" "main" {
  name              = local.airflow_name
  airflow_version   = local.environment_configuration.airflow_version
  environment_class = local.environment_configuration.airflow_environment_class

  execution_role_arn = module.airflow_execution_role.iam_role_arn

  source_bucket_arn = module.airflow_s3_bucket.bucket.arn
  dag_s3_path       = local.airflow_dag_s3_path

  network_configuration {
    security_group_ids = [module.airflow_security_group.security_group_id]
    subnet_ids         = slice(data.aws_subnets.shared-private.ids, 0, 1)
  }

  tags = local.tags
}

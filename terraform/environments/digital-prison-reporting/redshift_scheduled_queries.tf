module "redshift_scheduled_query_clear_expired_tables" {
  source = "./modules/redshift_scheduled_query"

  env                          = local.env
  name                         = "clear_expired_tables"
  description                  = "Deletes external tables that have existed for too long"
  project_id                   = local.project
  redshift_cluster_arn         = module.datamart.cluster_arn
  redshift_database_name       = module.datamart.cluster_database_name
  redshift_secrets_manager_arn = aws_secretsmanager_secret_version.redshift.arn
  schedule_expression          = "rate(1 hour)"
  sql_statement                = "SELECT 1;"

  tags = local.all_tags
}
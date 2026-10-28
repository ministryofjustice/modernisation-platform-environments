locals {
  eks_cluster_name = "${local.application_name}-${local.environment}-airflow"

  /* Environment Configuration */
  environment_configuration = local.environment_configurations[local.environment]

  # >>> TEMPORARY (Airflow 3 durability test): START - remove this block after the test
  /* Airflow workflow roles with access to a prefix of the MWAA bucket */
  mwaa_bucket_workflow_access = try(local.environment_configuration.mwaa_bucket_workflow_access, {})

  mwaa_bucket_workflow_role_arns = {
    for prefix, roles in local.mwaa_bucket_workflow_access : prefix => [
      for role in roles : "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/${role}"
    ]
  }

  mwaa_bucket_workflow_all_role_arns = distinct(flatten(values(local.mwaa_bucket_workflow_role_arns)))
  # <<< TEMPORARY (Airflow 3 durability test): END
}

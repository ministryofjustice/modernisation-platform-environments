module "schema_validation" {
  for_each = local.validation_deployments

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/data-contract-management/modules/schema-validation?ref=13bf052ef105c3a01ce66254f2750332e7270c72"

  name         = "${local.validation_function_prefix}-${each.key}"
  image_uri    = each.value.image_uri
  architecture = each.value.architecture

  ingestion_type  = each.value.ingestion_type
  source_mappings = each.value.source_mappings

  registry_table_name = module.schema_registration[0].contract_table_name
  registry_table_arn  = module.schema_registration[0].contract_table_arn

  registry_kms_key_arns = [
    aws_kms_key.contract_management["registration"].arn,
  ]

  contract_object_arns = [
    "${aws_s3_bucket.contract_management["contracts"].arn}/*",
  ]

  contract_kms_key_arns = [
    aws_kms_key.contract_management["contracts"].arn,
  ]

  incoming_kms_key_arns = each.value.incoming_kms_key_arns

  validation_table_kms_key_arn = aws_kms_key.schema_validation["${each.key}/audit"].arn
  log_kms_key_arn              = aws_kms_key.schema_validation["${each.key}/logs"].arn
  failure_queue_kms_key_arn    = aws_kms_key.schema_validation["${each.key}/failures"].arn

  timeout_seconds                = each.value.timeout_seconds
  memory_size_mb                 = each.value.memory_size_mb
  reserved_concurrent_executions = each.value.reserved_concurrent_executions

  log_retention_in_days             = 365
  table_deletion_protection_enabled = true

  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600

  monitoring_enabled = true
  alarm_action_arns  = each.value.alarm_action_arns

  tags = local.tags

  depends_on = [
    aws_ecr_repository_policy.schema_validation,
  ]
}

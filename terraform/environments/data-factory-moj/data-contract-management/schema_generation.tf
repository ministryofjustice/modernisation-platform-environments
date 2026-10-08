module "schema_generation" {
  for_each = local.generation_sources

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/data-contract-management/modules/schema-generation?ref=3b181c61e6fd0b49efeeb607d714dce278c2fc3e"

  name         = "${local.generation_function_prefix}-${each.key}"
  image_uri    = each.value.image_uri
  architecture = each.value.architecture

  source_config = {
    engine              = each.value.engine
    service             = each.value.service
    database_name       = each.value.database_name
    schema_name         = each.value.schema_name
    table_names         = each.value.table_names
    secret_arn          = each.value.secret_arn
    oracle_service_name = each.value.oracle_service_name
    oracle_sid          = each.value.oracle_sid
  }

  contract_namespace = each.value.contract_namespace
  contract_version   = each.value.contract_version
  contract_contacts  = each.value.contract_contacts

  schema_registry_bucket_name = aws_s3_bucket.contract_management["contracts"].id

  contract_object_arns = [
    "${aws_s3_bucket.contract_management["contracts"].arn}/${each.value.contract_object_prefix}/*",
  ]

  contract_kms_key_arns = [
    aws_kms_key.contract_management["contracts"].arn,
  ]

  secret_kms_key_arns = each.value.secret_kms_key_arns

  network = {
    subnet_ids = each.value.subnet_ids
    security_group_ids = [
      aws_security_group.schema_generation[each.key].id,
    ]
  }

  log_kms_key_arn = aws_kms_key.schema_generation["${each.key}/logs"].arn

  failure_queue_kms_key_arn = aws_kms_key.schema_generation["${each.key}/failures"].arn

  timeout_seconds                = each.value.timeout_seconds
  memory_size_mb                 = each.value.memory_size_mb
  reserved_concurrent_executions = each.value.reserved_concurrent_executions

  log_retention_in_days = 365

  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600

  monitoring_enabled = true
  alarm_action_arns  = each.value.alarm_action_arns

  tags = local.tags

  depends_on = [
    aws_ecr_repository_policy.schema_generation,
    aws_vpc_security_group_egress_rule.generation_database,
    aws_vpc_security_group_egress_rule.generation_https,
    aws_vpc_security_group_ingress_rule.database_from_generation,
    aws_s3_bucket_versioning.contract_management,
    aws_s3_bucket_server_side_encryption_configuration.contract_management,
    aws_s3_bucket_policy.contract_management,
  ]
}

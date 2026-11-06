module "schema_registration" {
  count = local.registration_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/data-contract-management/modules/schema-registration?ref=e36dc233e5939ab1d676feee32d6e14855d77a42"

  name         = local.registration_name
  image_uri    = local.registration_image_uri
  architecture = var.registration_architecture

  contract_object_arns = [
    "${aws_s3_bucket.contract_management["contracts"].arn}/*",
  ]

  contract_kms_key_arns = [
    aws_kms_key.contract_management["contracts"].arn,
  ]

  table_kms_key_arn = aws_kms_key.contract_management["registration"].arn

  log_kms_key_arn = aws_kms_key.contract_management["logs"].arn

  failure_queue_kms_key_arn = aws_kms_key.contract_management["failures"].arn

  timeout_seconds                = 60
  memory_size_mb                 = 256
  reserved_concurrent_executions = 5

  log_retention_in_days             = 365
  table_deletion_protection_enabled = true

  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 3600

  monitoring_enabled = true
  alarm_action_arns  = var.registration_alarm_action_arns

  tags = local.tags

  depends_on = [
    aws_ecr_repository_policy.schema_registration,
    aws_s3_bucket_versioning.contract_management,
    aws_s3_bucket_server_side_encryption_configuration.contract_management,
    aws_s3_bucket_policy.contract_management,
  ]
}

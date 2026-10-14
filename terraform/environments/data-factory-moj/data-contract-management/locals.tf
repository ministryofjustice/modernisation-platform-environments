locals {
  contract_management_enabled = local.is-development

  registration_name      = "${local.application_name}-${local.environment}-contracts"
  generation_name_prefix = "${local.application_name}-${local.environment}-contract-generation"

  generation_function_prefix = "df-moj-${local.environment}-gen"

  generation_sources = local.contract_management_enabled ? lookup(
    var.generation_sources_by_environment,
    local.environment,
    {}
  ) : {}

  registration_image_uri = lookup(
    var.registration_image_uris,
    local.environment,
    null
  )

  registration_enabled = (
    local.contract_management_enabled &&
    local.registration_image_uri != null
  )

  contract_bucket_names = local.contract_management_enabled ? {
    contracts   = "${local.registration_name}-${data.aws_caller_identity.current.account_id}"
    access_logs = "${local.registration_name}-logs-${data.aws_caller_identity.current.account_id}"
  } : {}

  contract_encryption_keys = local.contract_management_enabled ? {
    contracts    = "Encryption for stored data contracts"
    registration = "Encryption for the contract registration table"
    logs         = "Encryption for schema registration CloudWatch logs"
    failures     = "Encryption for schema registration failure messages"
  } : {}

  registration_log_group_arn = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.registration_name}"

  registration_execution_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.registration_name}-execution"
}

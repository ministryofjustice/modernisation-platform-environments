output "registration_ecr_repository_url" {
  description = "Repository URL used to publish the registration image."
  value = local.contract_management_enabled ? (
    aws_ecr_repository.schema_registration[0].repository_url
  ) : null
}

output "registration_ecr_repository_name" {
  description = "Registration image repository name."
  value = local.contract_management_enabled ? (
    aws_ecr_repository.schema_registration[0].name
  ) : null
}

output "contract_bucket_name" {
  description = "Bucket used to store data contracts."
  value = local.contract_management_enabled ? (
    aws_s3_bucket.contract_management["contracts"].id
  ) : null
}

output "contract_bucket_arn" {
  description = "Contract bucket ARN for integration permissions."
  value = local.contract_management_enabled ? (
    aws_s3_bucket.contract_management["contracts"].arn
  ) : null
}

output "contract_kms_key_arn" {
  description = "Encryption key for contract writers and readers."
  value = local.contract_management_enabled ? (
    aws_kms_key.contract_management["contracts"].arn
  ) : null
}

output "registration_function_name" {
  description = "Schema registration Lambda function name."
  value = local.registration_enabled ? (
    module.schema_registration[0].function_name
  ) : null
}

output "registration_function_arn" {
  description = "Registration Lambda ARN for future workflow integration."
  value = local.registration_enabled ? (
    module.schema_registration[0].function_arn
  ) : null
}

output "registration_contract_table_name" {
  description = "Table containing registered contract versions."
  value = local.registration_enabled ? (
    module.schema_registration[0].contract_table_name
  ) : null
}

output "registration_log_group_name" {
  description = "CloudWatch log group used by registration."
  value = local.registration_enabled ? (
    module.schema_registration[0].log_group_name
  ) : null
}

output "registration_failure_queue_url" {
  description = "Queue used to inspect failed asynchronous invocations."
  value = local.registration_enabled ? (
    module.schema_registration[0].failure_queue_url
  ) : null
}

output "registration_alarm_arns" {
  description = "Registration operational alarms."
  value = local.registration_enabled ? (
    module.schema_registration[0].alarm_arns
  ) : null
}

output "generation_ecr_repository_name" {
  description = "Repository name for the schema generation runtime image."
  value = local.contract_management_enabled ? (
    aws_ecr_repository.schema_generation[0].name
  ) : null
}

output "generation_ecr_repository_url" {
  description = "Repository URL used to publish the schema generation runtime image."
  value = local.contract_management_enabled ? (
    aws_ecr_repository.schema_generation[0].repository_url
  ) : null
}

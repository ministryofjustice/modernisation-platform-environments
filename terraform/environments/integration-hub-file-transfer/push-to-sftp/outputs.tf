output "delivery_roles" {
  description = "Delivery role and authorised source and destination for each configured push-to-sftp dispatch entry."
  value = {
    for entry_id, role in module.iam_role_delivery : entry_id => {
      identity             = local.push_to_sftp_entries[entry_id].identity
      source_prefix        = local.push_to_sftp_entries[entry_id].source_prefix
      destination_hostname = local.push_to_sftp_entries[entry_id].action.push_to_sftp.hostname
      destination_prefix   = local.push_to_sftp_entries[entry_id].action.push_to_sftp.destination_prefix
      role_arn             = role.arn
    }
  }
}

output "pipeline" {
  description = "Shared push-to-sftp pipeline resource identifiers."
  value = {
    eventbridge_rule_arn = module.eventbridge_push_to_sftp.eventbridge_rule_arns["push-to-sftp"]
    sns_topic_arn        = module.sns_push_to_sftp.topic_arn
    sqs_queue_arn        = module.sqs_processing.queue_arn
    sqs_dlq_arn          = module.sqs_dlq["processing"].queue_arn
    eventbridge_dlq_arn  = module.sqs_dlq["eventbridge"].queue_arn
    sns_dlq_arn          = module.sqs_dlq["sns"].queue_arn
    processing_dlq_arn   = module.sqs_dlq["processing"].queue_arn
    dlq_reporter_arn     = module.lambda_dlq_reporter.lambda_function_arn
  }
}

output "credential_secrets" {
  description = "Metadata-only keypair containers; populate through approved operator tooling, never Terraform."
  value = {
    for entry_id in keys(local.push_to_sftp_entries) : entry_id => {
      private_key_arn = module.secrets_private_key[entry_id].secret_arn
      public_key_arn  = module.secrets_public_key[entry_id].secret_arn
    }
  }
}

output "operator_policy_arns" {
  description = "Unattached, per-entry policies for approved public-key readers and key custodians."
  value = {
    for entry_id in keys(local.push_to_sftp_entries) : entry_id => {
      public_key_reader = module.iam_policy_public_key_reader[entry_id].arn
      key_custodian     = module.iam_policy_key_custodian[entry_id].arn
    }
  }
}

output "delivery_role_arns" {
  description = "Per-entry source-version and private-key reader roles."
  value       = { for entry_id, role in module.iam_role_delivery : entry_id => role.arn }
}

output "processing_queue_url" {
  description = "SFTP processing queue URL."
  value       = module.sqs_processing.queue_url
}

output "dead_letter_queue_urls" {
  description = "EventBridge, SNS subscription and processing dead-letter queues."
  value       = { for name, queue in module.sqs_dlq : name => queue.queue_url }
}
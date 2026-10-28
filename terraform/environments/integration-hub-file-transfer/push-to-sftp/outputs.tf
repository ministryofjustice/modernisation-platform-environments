output "delivery_enabled" {
  description = "Whether SFTP requests and processing queue consumption are enabled."
  value       = local.delivery_enabled
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
  description = "SFTP processing queue, disabled for Lambda consumption until explicitly enabled."
  value       = module.sqs_processing.queue_url
}

output "dead_letter_queue_urls" {
  description = "EventBridge, SNS subscription and processing dead-letter queues."
  value       = { for name, queue in module.sqs_dlq : name => queue.queue_url }
}
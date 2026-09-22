output "delivery_roles" {
  description = "Predictable delivery role ARN for each configured push-to-s3 dispatch entry."
  value = {
    for entry_id, role in module.iam_role_delivery : entry_id => {
      identity           = local.push_to_s3_entries[entry_id].identity
      source_prefix      = local.push_to_s3_entries[entry_id].source_prefix
      destination_bucket = local.push_to_s3_entries[entry_id].action.push_to_s3.bucket_id
      destination_prefix = local.push_to_s3_entries[entry_id].action.push_to_s3.destination_prefix
      role_arn           = role.arn
    }
  }
}

output "pipeline" {
  description = "Shared push-to-s3 pipeline resource identifiers."
  value = {
    eventbridge_rule_arn = module.eventbridge_push_to_s3.eventbridge_rule_arns["push-to-s3"]
    sns_topic_arn        = module.sns_push_to_s3.topic_arn
    sqs_queue_arn        = module.sqs_push_to_s3.queue_arn
    sqs_dlq_arn          = module.sqs_push_to_s3_dlq.queue_arn
  }
}
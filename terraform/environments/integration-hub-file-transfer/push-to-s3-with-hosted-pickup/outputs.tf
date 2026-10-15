output "hosted_pickup_destinations" {
  description = "Isolated hosted pickup resources for each configured dispatch entry."
  value = {
    for entry_id, role in module.iam_role_mover : entry_id => {
      identity           = local.hosted_pickup_entries[entry_id].identity
      source_prefix      = local.hosted_pickup_entries[entry_id].source_prefix
      destination_bucket = module.s3_hosted_pickup[entry_id].s3_bucket_id
      destination_prefix = local.hosted_pickup_entries[entry_id].action.push_to_s3_with_hosted_pickup.destination_prefix
      retention_days     = local.hosted_pickup_entries[entry_id].action.push_to_s3_with_hosted_pickup.retention_days
      kms_key_arn        = module.kms_hosted_pickup[entry_id].key_arn
      mover_role_arn     = role.arn
      pickup_role_arn    = module.iam_role_customer_pickup[entry_id].arn
    }
  }
}

output "pipeline" {
  description = "Shared push-to-s3-with-hosted-pickup pipeline resource identifiers."
  value = {
    eventbridge_rule_arn = module.eventbridge_hosted_pickup.eventbridge_rule_arns["push-to-s3-with-hosted-pickup"]
    sns_topic_arn        = module.sns_hosted_pickup.topic_arn
    sqs_queue_arn        = module.sqs_hosted_pickup.queue_arn
    sqs_dlq_arn          = module.sqs_hosted_pickup_dlq.queue_arn
    eventbridge_dlq_arn  = module.sqs_hosted_pickup_eventbridge_dlq.queue_arn
    sns_dlq_arn          = module.sqs_hosted_pickup_sns_dlq.queue_arn
    processing_dlq_arn   = module.sqs_hosted_pickup_dlq.queue_arn
    dlq_reporter_arn     = module.lambda_dlq_reporter.lambda_function_arn
  }
}
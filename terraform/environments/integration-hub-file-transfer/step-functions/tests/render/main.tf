locals {
  definition = templatefile("../../file-transfer-workflow.asl.json", {
    account_id                 = jsonencode("123456789012")
    event_bus_arn              = jsonencode("arn:aws:events:eu-west-2:123456789012:event-bus/integration-hub-file-transfer")
    event_idempotency_table    = jsonencode("integration-hub-file-transfer-development-idempotency")
    processing_kms_key_arn     = jsonencode("arn:aws:kms:eu-west-2:123456789012:key/12345678-1234-1234-1234-123456789012")
    idempotency_table_name     = jsonencode("integration-hub-file-transfer-development-file-transfer-workflow-idempotency")
    incoming_bucket_name       = jsonencode("integration-hub-file-transfer-development-incoming")
    lease_seconds              = 90000
    maximum_size_bytes         = 5000000000000
    multipart_max_concurrency  = 4
    part_size_bytes            = 5000000000
    processing_bucket_name     = jsonencode("integration-hub-file-transfer-development-processing")
    record_retention_seconds   = 2592000
    state_machine_timeout_secs = 86400
  })
}

output "definition" {
  value = local.definition
}
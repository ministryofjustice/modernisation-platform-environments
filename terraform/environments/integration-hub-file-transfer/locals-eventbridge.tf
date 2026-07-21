locals {
  eventbridge_schema_directory = "${path.module}/schemas"
  eventbridge_schemas          = fileset("${path.module}/schemas", "*.json")
  file_transfer_event_bus_arn  = "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:event-bus/${local.application_name}"
}

locals {
  eventbridge_schema_directory = "${path.module}/schemas"
  eventbridge_schemas          = fileset("${path.module}/schemas", "*.json")

  eventbridge_retention_days = local.is-production ? 400 : 30
}

locals {
  eventbridge_schema_directory = "${path.module}/schemas"
  eventbridge_schemas          = fileset("${path.module}/schemas", "*.json")
}
resource "aws_schemas_registry" "this" {
  name        = local.application_name
  description = "${local.application_name} EventBridge schema registry"
}

resource "aws_schemas_schema" "this" {
  for_each      = local.eventbridge_schemas
  name          = trimsuffix(basename(each.value), ".json")
  registry_name = aws_schemas_registry.this.name
  type          = "JSONSchemaDraft4"

  content = file("${local.eventbridge_schema_directory}/${each.value}")
}
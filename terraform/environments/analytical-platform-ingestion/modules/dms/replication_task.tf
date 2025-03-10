# Local to parse the JSON
locals {
  input_data = jsondecode(var.dms_mapping_rules)
  objects    = [for object in local.input_data.objects : replace(object, "-", "_")]
  blobs      = local.input_data.blobs
  rules = flatten(concat(
    [
      for idx, obj in local.objects : {
        rule-type   = "selection"
        rule-id     = idx + 1 # Using iteration number (1-based index)
        rule-name   = "include-${lower(obj)}"
        rule-action = "explicit"
        object-locator = {
          schema-name = local.input_data.schema
          table-name  = obj
        }
      }
    ],
    [
      for idx, obj in local.objects : {
        rule-type   = "transformation"
        rule-id     = length(local.objects) + idx + 1
        rule-name   = "add-scn-${lower(obj)}"
        rule-action = "add-column"
        rule-target = "column"
        value       = "SCN"
        expression  = "$AR_H_STREAM_POSITION"
        data-type = {
          type   = "string"
          length = 50
        }
        object-locator = {
          schema-name = local.input_data.schema
          table-name  = obj
        }
      }
    ],
    [
      # Generate transformation rules for removing columns
      for idx, blob in local.blobs : {
        rule-type   = "transformation"
        rule-id     = (length(local.objects) * 2) + idx + 1
        rule-name   = "remove-${lower(blob.column_name)}-from-${lower(blob.object_name)}"
        rule-action = "remove-column"
        rule-target = "column"
        object-locator = {
          schema-name = local.input_data.schema
          table-name  = blob.object_name
          column-name = blob.column_name
        }
      }
    ],
    [
      for idx, obj in local.objects : {
        rule-type   = "transformation"
        rule-id     = (length(local.objects) * 3) + idx + 1
        rule-name   = "rename-${lower(obj)}"
        rule-action = "rename"
        rule-target = "table"
        value       = replace(obj, "_MV", "")
        object-locator = {
          schema-name = "MPTUSER"
          table-name  = obj
        }
      }
      if endswith(obj, "_MV")
    ],
  ))
}


output "terraform_rules" {
  value = local.rules
}

resource "aws_dms_replication_task" "full_load_replication_task" {
  migration_type            = "full-load"
  replication_instance_arn  = aws_dms_replication_instance.instance.replication_instance_arn
  replication_task_id       = var.replication_task_id.full_load
  replication_task_settings = file("${path.module}/default_task_settings.json")
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_s3_endpoint.s3_target.endpoint_arn
  table_mappings            = jsonencode({ rules : local.rules })
  start_replication_task    = false

  tags = merge(
    { Name = var.replication_task_id.full_load },
  var.tags)
}

resource "aws_dms_replication_task" "cdc_replication_task" {
  migration_type            = "cdc"
  cdc_start_time            = var.dms_source.cdc_start_time
  replication_instance_arn  = aws_dms_replication_instance.instance.replication_instance_arn
  replication_task_id       = var.replication_task_id.cdc
  replication_task_settings = file("${path.module}/default_task_settings.json")
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_s3_endpoint.s3_target.endpoint_arn
  table_mappings            = jsonencode({ rules : local.rules })
  start_replication_task    = false

  tags = merge(
    { Name = var.replication_task_id.cdc },
    var.tags
  )
}

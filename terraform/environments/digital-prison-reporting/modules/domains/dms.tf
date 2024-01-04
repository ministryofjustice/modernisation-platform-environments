# Create a new DMS replication instance
data "template_file" "table-mappings" {
  template = var.table_mappings

  vars = {
    input_schema = var.rename_rule_source_schema
    output_space = var.rename_rule_output_space
  }
}

resource "aws_dms_replication_task" "dms-replication" {
  count = var.enable_replication_task ? 1 : 0

  migration_type            = var.migration_type
  replication_instance_arn  = var.dms_replication_instance
  replication_task_id       = "${var.name}-task-${var.env}"
  source_endpoint_arn       = var.dms_source_endpoint # aws_dms_endpoint.dms-s3-target-source[0].endpoint_arn
  target_endpoint_arn       = var.dms_target_endpoint # aws_dms_s3_endpoint.dms-s3-target-endpoint[0].endpoint_arn
  table_mappings            = data.template_file.table-mappings.rendered
  replication_task_settings = var.replication_task_settings #JSON

  depends_on = [
    aws_dms_replication_instance.dms-s3-target-instance
  ]

  tags = merge(
    var.tags,
  {
    name = "${var.name}-task-${var.env}"
  })

}
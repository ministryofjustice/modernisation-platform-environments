# Create a new DMS replication instance
resource "aws_dms_replication_instance" "dms" {
  #checkov:skip=CKV_AWS_222: "Ensure DMS replication instance gets all minor upgrade automatically"
  #checkov:skip=CKV_AWS_212: "Ensure DMS replication instance is encrypted by KMS using a customer managed Key (CMK)"
  count = var.setup_dms_instance ? 1 : 0

  allocated_storage            = var.replication_instance_storage
  apply_immediately            = true
  auto_minor_version_upgrade   = false
  availability_zone            = var.availability_zone
  engine_version               = var.replication_instance_version
  multi_az                     = true
  preferred_maintenance_window = var.replication_instance_maintenance_window
  publicly_accessible          = false
  replication_instance_class   = var.replication_instance_class
  replication_instance_id      = var.name
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms[0].id
  vpc_security_group_ids       = aws_security_group.dms_sec_group[*].id

  tags = var.tags

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    aws_iam_role_policy_attachment.dms-operator-kinesis-attachment,
    aws_iam_role_policy_attachment.dms-kinesis-attachment,
    var.cloudwatch_role_dependency,
    var.vpc_role_dependency,
    aws_dms_replication_subnet_group.dms,
    aws_security_group.dms_sec_group
  ]
}

data "template_file" "table-mappings" {
  template = file("${path.module}/config/${var.short_name}-table-mappings.json.tpl")
}

resource "aws_dms_replication_task" "dms-replication" {
  count = var.setup_dms_instance && var.enable_replication_task ? 1 : 0

  migration_type            = var.migration_type
  replication_instance_arn  = aws_dms_replication_instance.dms[0].replication_instance_arn
  replication_task_id       = "${var.project_id}-dms-task-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}"
  source_endpoint_arn       = aws_dms_endpoint.source[0].endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target[0].endpoint_arn
  table_mappings            = data.template_file.table-mappings.rendered
  replication_task_settings = file("${path.module}/config/${var.short_name}-replication-settings.json")

  #lifecycle {
  #  ignore_changes = [replication_task_settings]
  #}

  depends_on = [
    aws_dms_replication_instance.dms,
    aws_dms_endpoint.source,
    aws_dms_endpoint.target
  ]
}

# Create an endpoint for the source database
resource "aws_dms_endpoint" "source" {
  #checkov:skip=CKV2_AWS_49: "Ensure AWS Database Migration Service endpoints have SSL configured - Will resolve through Spike"
  #checkov:skip=CKV_AWS_296: "Ensure DMS endpoint uses Customer Managed Key (CMK).TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083


  count = var.setup_dms_instance ? 1 : 0

  database_name = var.source_db_name
  endpoint_id   = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-source"
  endpoint_type = "source"
  engine_name   = var.source_engine_name
  password      = var.source_app_password
  port          = var.source_db_port
  server_name   = var.source_address
  ssl_mode      = "none"
  username      = var.source_app_username

  extra_connection_attributes = var.extra_attributes

  tags = var.tags

  depends_on = [
    aws_dms_replication_instance.dms
  ]
}

# Create an endpoint for the target Kinesis
resource "aws_dms_endpoint" "target" {
  #checkov:skip=CKV2_AWS_49: "Ensure AWS Database Migration Service endpoints have SSL configured - Will resolve through Spike"

  #checkov:skip=CKV_AWS_296: "Ensure DMS endpoint uses Customer Managed Key (CMK).TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083

  count = var.setup_dms_instance ? 1 : 0

  endpoint_id   = "${var.project_id}-dms-${var.short_name}-${var.dms_target_name}-target"
  endpoint_type = "target"
  engine_name   = var.target_engine

  dynamic "kinesis_settings" {
    for_each = var.kinesis_settings != null ? [true] : []
    content {
      include_control_details        = lookup(var.kinesis_settings, "include_control_details", null)
      include_null_and_empty         = lookup(var.kinesis_settings, "include_null_and_empty", null)
      include_partition_value        = lookup(var.kinesis_settings, "include_partition_value", null)
      include_table_alter_operations = lookup(var.kinesis_settings, "include_table_alter_operations", null)
      include_transaction_details    = lookup(var.kinesis_settings, "include_transaction_details", null)
      message_format                 = lookup(var.kinesis_settings, "message_format", null)
      partition_include_schema_table = lookup(var.kinesis_settings, "partition_include_schema_table", null)
      service_access_role_arn        = aws_iam_role.dms-kinesis-role.arn
      stream_arn                     = lookup(var.kinesis_settings, "kinesis_target_stream", null)
    }
  }

  tags = var.tags

  depends_on = [
    aws_dms_replication_instance.dms
  ]
}

# Create a subnet group using existing VPC subnets
resource "aws_dms_replication_subnet_group" "dms" {
  count = var.setup_dms_instance ? 1 : 0

  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}-subnet-group"
  subnet_ids                           = var.subnet_ids
}

# Security Groups
resource "aws_security_group" "dms_sec_group" {

  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  count = var.setup_dms_instance ? 1 : 0

  name   = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-${var.dms_target_name}-security-group"
  vpc_id = var.vpc

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
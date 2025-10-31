### DMS replication instance log group
resource "aws_cloudwatch_log_group" "dms-instance-log-group" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for Timebeing in view of Cost Savings”

  count = var.setup_dms_instance ? 1 : 0
  name  = "dms-tasks-${var.name}-instance-${var.env}"

  retention_in_days = var.dms_log_retention_in_days

  tags = merge(
    var.tags,
    {
      name = "${var.name}-instance-log-group-${var.env}"
  })
}

### DMS replication instance
resource "aws_dms_replication_instance" "dms-s3-target-instance" {
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
  replication_instance_id      = "${var.name}-instance-${var.env}"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms-s3-target-subnet-group[0].id
  vpc_security_group_ids       = aws_security_group.dms_s3_target_sec_group[*].id
  allow_major_version_upgrade  = var.allow_major_version_upgrade

  tags = merge(
    var.tags,
    {
      name = "${var.name}-instance-${var.env}"
  })

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    aws_dms_replication_subnet_group.dms-s3-target-subnet-group,
    aws_security_group.dms_s3_target_sec_group,
    aws_cloudwatch_log_group.dms-instance-log-group
  ]
}

# Create a subnet group using existing VPC subnets
resource "aws_dms_replication_subnet_group" "dms-s3-target-subnet-group" {
  count = var.setup_dms_instance ? 1 : 0

  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "${var.name}-sg"
  subnet_ids                           = var.subnet_ids
}

# Security Groups
resource "aws_security_group" "dms_s3_target_sec_group" {
  count = var.setup_dms_instance ? 1 : 0

  name   = "${var.name}-sg"
  vpc_id = var.vpc

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr
  }
  ingress {
    from_port   = 1521
    to_port     = 1521
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

### DMS Task
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

  tags = merge(
    var.tags,
    {
      name = "${var.name}-task-${var.env}"
  })

}

### DMS Endpoints
# Create an endpoint for the source database
resource "aws_dms_endpoint" "dms-s3-target-source" {
  #checkov:skip=CKV2_AWS_49: "Ensure AWS Database Migration Service endpoints have SSL configured - Will resolve through Spike"

  count = var.setup_dms_endpoints && var.setup_dms_source_endpoint ? 1 : 0

  database_name = var.source_db_name
  endpoint_id   = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-source-endpoint"
  endpoint_type = "source"
  engine_name   = var.source_engine_name
  password      = var.source_app_password
  port          = var.source_db_port
  server_name   = var.source_address
  ssl_mode      = var.source_ssl_mode
  username      = var.source_app_username

  dynamic "postgres_settings" {
    for_each = var.source_engine_name == "postgres" ? [1] : []

    content {
      map_boolean_as_boolean       = true
      fail_tasks_on_lob_truncation = true
      heartbeat_enable             = var.source_postgres_heartbeat_enable
      heartbeat_frequency          = var.source_postgres_heartbeat_frequency
    }
  }

  extra_connection_attributes = var.extra_attributes

  tags = merge(
    var.tags,
    {
      Resource_Type = "DMS Source Endpoint"
  })
}

resource "aws_dms_s3_endpoint" "dms-s3-target-endpoint" {
  count = var.setup_dms_endpoints && var.setup_dms_s3_endpoint ? 1 : 0

  endpoint_id                      = "${var.project_id}-dms-${var.short_name}-s3-target-endpoint"
  endpoint_type                    = "target"
  bucket_name                      = var.bucket_name
  service_access_role_arn          = aws_iam_role.dms-s3-role[0].arn
  data_format                      = "parquet"
  cdc_path                         = "cdc"
  timestamp_column_name            = "_timestamp"
  parquet_timestamp_in_millisecond = false
  include_op_for_full_load         = true

  max_file_size          = 120000
  cdc_max_batch_interval = 10

  tags = merge(
    var.tags,
    {
      Resource_Type = "DMS Target Endpoint"
  })
}
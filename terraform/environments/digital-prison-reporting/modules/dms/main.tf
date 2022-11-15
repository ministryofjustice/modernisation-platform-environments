# Create a new DMS replication instance
resource "aws_dms_replication_instance" "dms" {
  allocated_storage            = "${var.replication_instance_storage}"
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = "eu-west-2a"
  engine_version               = "${var.replication_instance_version}"
  multi_az                     = false
  preferred_maintenance_window = "${var.replication_instance_maintenance_window}"
  publicly_accessible          = false
  replication_instance_class   = "${var.replication_instance_class}"
  replication_instance_id      = var.name
  replication_subnet_group_id  = "${aws_dms_replication_subnet_group.dms.id}"
  vpc_security_group_ids       = ["${aws_dms_replication_subnet_group.dms.id}"]

  tags = var.tags
}

data "template_file" "table-mappings-from-oracle-to-kinesis" {
  template = file("${path.module}/config/table-mappings-from-oracle-to-kinesis.json.tpl")
}

resource "aws_dms_replication_task" "rt-mssql-pg" {
  count                     = 0  
  migration_type            = "cdc"
  replication_instance_arn  = aws_dms_replication_instance.dms.replication_instance_arn
  replication_task_id       = "dms-rt-mssql-pg"
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = data.template_file.table-mappings-from-oracle-to-kinesis.rendered
  replication_task_settings = file("${path.module}/config/replication-settings.json")


  lifecycle {
	  ignore_changes = ["replication_task_settings"]
  }
}

# Create an endpoint for the source database
resource "aws_dms_endpoint" "source" {
  database_name = "${var.source_db_name}"
  endpoint_id   = "${var.stack_name}-dms-${var.environment}-source"
  endpoint_type = "source"
  engine_name   = "${var.source_engine_name}"
  password      = "${var.source_app_password}"
  port          = "${var.source_db_port}"
  server_name   = var.source_address // TBC
  ssl_mode      = "none"
  username      = "${var.source_app_username}"

  tags = var.tags
}

# Create an endpoint for the target Kinesis
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.stack_name}-dms-${var.environment}-target"
  endpoint_type = "target"
  engine_name   = "${var.target_engine}"

  kinesis_settings {
    service_access_role_arn        = aws_iam_role.dms-kinesis-role.arn
    stream_arn                     = var.kinesis_target_stream
    partition_include_schema_table = true
    include_partition_value        = true
  }

  tags = var.tags
}

# Create a subnet in each availability zone
resource "aws_subnet" "database" {
  count  = "${length(var.availability_zones)}"
  vpc_id = var.vpc

  cidr_block        = "${element(var.database_subnet_cidr, count.index)}"
  availability_zone = "${lookup(var.availability_zones, count.index)}"

  tags = var.tags

}

# Create a subnet group using existing VPC subnets
resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "dms-replication-subnet-group-tf"
  subnet_ids                           = ["${aws_subnet.database.*.id}"]
}
# Create a new DMS replication instance
resource "aws_dms_replication_instance" "dms" {
  allocated_storage            = var.replication_instance_storage
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = var.availability_zone
  engine_version               = var.replication_instance_version
  multi_az                     = true
  preferred_maintenance_window = var.replication_instance_maintenance_window
  publicly_accessible          = false
  replication_instance_class   = var.replication_instance_class
  replication_instance_id      = var.name
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms.id
  vpc_security_group_ids       = [aws_security_group.dms_sec_group.id]

  tags = var.tags

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }  
}

data "template_file" "table-mappings-from-oracle-to-kinesis" {
  template = file("${path.module}/config/table-mappings-from-oracle-to-kinesis.json.tpl")
}

resource "aws_dms_replication_task" "dms-replication" {
  count                     = 1
  migration_type            = var.migration_type
  replication_instance_arn  = aws_dms_replication_instance.dms.replication_instance_arn
  replication_task_id       = "${var.project_id}-dms-task-${var.dms_src_target}"
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = data.template_file.table-mappings-from-oracle-to-kinesis.rendered
  replication_task_settings = file("${path.module}/config/replication-settings.json")


  lifecycle {
    ignore_changes = [replication_task_settings]
  }

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }  
}

# Create an endpoint for the source database
resource "aws_dms_endpoint" "source" {
  database_name = var.source_db_name
  endpoint_id   = "${var.project_id}-dms-${var.dms_src_target}-source-${var.env}"
  endpoint_type = "source"
  engine_name   = var.source_engine_name
  password      = var.source_app_password
  port          = var.source_db_port
  server_name   = var.source_address // TBC
  ssl_mode      = "none"
  username      = var.source_app_username

  tags = var.tags
}

# Create an endpoint for the target Kinesis
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.project_id}-dms-${var.dms_src_target}-target-${var.env}"
  endpoint_type = "target"
  engine_name   = var.target_engine

  kinesis_settings {
    service_access_role_arn        = aws_iam_role.dms-kinesis-role.arn
    stream_arn                     = "arn:aws:kinesis:eu-west-2:771283872747:stream/dpr-kinesis-ingestor-development" #var.kinesis_target_stream
    partition_include_schema_table = true
    include_partition_value        = true
  }

  tags = var.tags
}

# Use below to setup Subnet ID's Dynamically
# Create a subnet in each availability zone
#resource "aws_subnet" "database" {
#  count  = length(var.availability_zones)
#  vpc_id = var.vpc

#  cidr_block        = element(var.database_subnet_cidr, count.index)
#  availability_zone = lookup(var.availability_zones, count.index)

#  tags = merge(
#    var.tags,
#    {
#      subnet_index = "dms-pri-subnet-${count.index + 1}"
#    }
#  )
#}

# Create a subnet group using existing VPC subnets
resource "aws_dms_replication_subnet_group" "dms" {
  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "${var.project_id}-dms-${var.dms_src_target}-subnet-group"
  subnet_ids                           = var.subnet_ids
}

# Security Groups
resource "aws_security_group" "dms_sec_group" {
  name   = "${var.project_id}-dms-${var.dms_src_target}-security-group"
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
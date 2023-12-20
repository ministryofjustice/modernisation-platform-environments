# Create a new DMS replication instance
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

  tags = merge(
    var.tags,
  {
    name = "${var.name}-${var.resource}-${var.env}"
  })

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    var.cloudwatch_role_dependency,
    var.vpc_role_dependency,
    aws_dms_replication_subnet_group.dms-s3-target-subnet-group,
    aws_security_group.dms_s3_target_sec_group
  ]
}

data "template_file" "table-mappings" {
  template = var.table_mappings

  vars = {
    input_schema = var.rename_rule_source_schema
    output_space = var.rename_rule_output_space
  }
}

resource "aws_dms_replication_task" "dms-replication" {
  count = var.setup_dms_instance && var.enable_replication_task ? 1 : 0

  migration_type            = var.migration_type
  replication_instance_arn  = aws_dms_replication_instance.dms-s3-target-instance[0].replication_instance_arn
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
    name = "${var.name}-${var.resource}-${var.env}"
  })

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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
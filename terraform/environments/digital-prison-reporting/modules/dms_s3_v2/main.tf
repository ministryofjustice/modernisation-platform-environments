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
    name = "${var.name}-instance-${var.env}"
  })

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    aws_dms_replication_subnet_group.dms-s3-target-subnet-group,
    aws_security_group.dms_s3_target_sec_group
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
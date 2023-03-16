resource "aws_efs_file_system" "oem_db_efs" {
  encrypted        = true
  kms_key_id       = data.aws_kms_key.ebs_shared.arn
  performance_mode = "generalPurpose"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-efs"
    "volume-attach-host"   = "db",
    "volume-attach-device" = "efs://",
    "volume-mount-path"    = "/opt/oem/backups"
  }), local.tags)
}

resource "aws_efs_mount_target" "oem_db_efs" {
  file_system_id = aws_efs_file_system.oem_db_efs.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.oem_db_efs_sg.id
  ]
}

resource "aws_security_group" "oem_db_efs_sg" {
  name_prefix = "${local.application_name}-db-efs-sg-"
  description = "Allow inbound access from instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-efs-sg" }
  ), local.tags)

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}
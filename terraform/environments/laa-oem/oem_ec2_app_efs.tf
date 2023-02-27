resource "aws_efs_file_system" "oem-app-efs" {
  encrypted        = true
  performance_mode = "generalPurpose"
  tags = merge(tomap({
    "Name" = "${local.application_name}-app-efs"
  }), local.tags)
}

resource "aws_efs_mount_target" "oem-app-efs" {
  file_system_id = aws_efs_file_system.oem-app-efs.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.oem-app-efs-sg.id
  ]
}

resource "aws_security_group" "oem-app-efs-sg" {
  name_prefix = "${local.application_name}-oem-app-efs-sg"
  description = "Allow inbound access from instances"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049
    cidr_blocks = [data.aws_subnets.shared-public.ids]
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

  tags = local.tags
}

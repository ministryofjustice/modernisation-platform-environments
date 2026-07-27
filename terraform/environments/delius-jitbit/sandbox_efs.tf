resource "aws_efs_file_system" "jitbit_lucene" {
  creation_token = "${local.application_name}-efs-sandbox"

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.application_name}-sandbox-efs"
  }
}

resource "aws_efs_mount_target" "jitbit_lucene" {
  for_each = toset(data.aws_subnets.shared-public.ids)

  file_system_id  = aws_efs_file_system.jitbit_lucene.id
  subnet_id       = each.value
  security_groups = [
    aws_security_group.efs.id
  ]
}

resource "aws_efs_access_point" "jitbit_lucene" {
  file_system_id = aws_efs_file_system.jitbit_lucene.id

  root_directory {
    path = "/lucene"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  tags = {
    Name = "${local.application_name}-sandbox-efs-ap"
  }
}

resource "aws_security_group" "efs" {
  name   = "${local.application_name}-efs-sandbox"
  vpc_id = data.aws_vpc.shared.id

  ingress {
    description     = "NFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [
      aws_security_group.ecs_tasks.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
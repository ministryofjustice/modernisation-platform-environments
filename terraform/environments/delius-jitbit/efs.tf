resource "aws_efs_file_system" "lucene" {
  creation_token = "${local.application_name}-efs"

  encrypted  = true
  kms_key_id = data.aws_kms_key.general_shared.arn

  throughput_mode = local.is-production ? "elastic" : "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.application_name}-efs"
  }
}

resource "aws_efs_mount_target" "lucene" {
  for_each = toset(data.aws_subnets.shared-private.ids)

  file_system_id = aws_efs_file_system.lucene.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs.id
  ]
}

resource "aws_efs_access_point" "lucene" {
  file_system_id = aws_efs_file_system.lucene.id

  root_directory {
    path = "/SearchIndex"

    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }

  posix_user {
    uid = 1001
    gid = 1001
  }

  tags = {
    Name = "${local.application_name}-efs-ap"
  }
}

resource "aws_ssm_parameter" "efs_id" {
  name   = "/${local.application_name}/${local.environment}/efs-id"
  type   = "SecureString"
  value  = aws_efs_file_system.lucene.id
  key_id = data.aws_kms_key.general_shared.arn
}

resource "aws_ssm_parameter" "efs_ap_id" {
  name   = "/${local.application_name}/${local.environment}/efs-access-point-id"
  type   = "SecureString"
  value  = aws_efs_access_point.lucene.id
  key_id = data.aws_kms_key.general_shared.arn
}

resource "aws_security_group" "efs" {
  #checkov:skip=CKV_AWS_382:"Required for ECS tasks to access external services"

  name        = "${local.application_name}-efs"
  description = "EFS SG"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [
      aws_security_group.jitbit.id
    ]
  }

  egress {
    description = "All Traffic Out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

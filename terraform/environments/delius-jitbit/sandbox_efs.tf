resource "aws_efs_file_system" "lucene_sandbox" {
  count = local.is-development ? 1 : 0

  creation_token = "${local.application_name}-efs-sandbox"

  encrypted  = true
  kms_key_id = data.aws_kms_key.general_shared.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.application_name}-sandbox-efs"
  }
}

resource "aws_efs_mount_target" "lucene_sandbox" {
  for_each = local.is-development ? toset(data.aws_subnets.shared-private.ids) : toset([])

  file_system_id = aws_efs_file_system.lucene_sandbox[0].id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs_sandbox[0].id
  ]
}

resource "aws_efs_access_point" "lucene_sandbox" {
  count = local.is-development ? 1 : 0

  file_system_id = aws_efs_file_system.lucene_sandbox[0].id

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
    Name = "${local.application_name}-sandbox-efs-ap"
  }
}

resource "aws_ssm_parameter" "efs_id_sandbox" {
  count  = local.is-development ? 1 : 0
  name   = "/${local.application_name}/sandbox/efs-id"
  type   = "SecureString"
  value  = aws_efs_file_system.lucene_sandbox[0].id
  key_id = data.aws_kms_key.general_shared.arn
}

resource "aws_ssm_parameter" "efs_ap_id_sandbox" {
  count  = local.is-development ? 1 : 0
  name   = "/${local.application_name}/sandbox/efs-access-point-id"
  type   = "SecureString"
  value  = aws_efs_access_point.lucene_sandbox[0].id
  key_id = data.aws_kms_key.general_shared.arn
}

resource "aws_security_group" "efs_sandbox" {
  #checkov:skip=CKV_AWS_382:"Required for ECS tasks to access external services"
  count = local.is-development ? 1 : 0

  name        = "${local.application_name}-efs-sandbox"
  description = "EFS SG"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [
      aws_security_group.jitbit_sandbox[0].id
    ]
  }

  egress {
    description = "Allow All Out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}